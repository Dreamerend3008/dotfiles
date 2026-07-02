#!/usr/bin/env python3
import json
import os
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any

import msal
import requests
from zoneinfo import ZoneInfo

GRAPH_BASE = "https://graph.microsoft.com/v1.0"
DEFAULT_SCOPES = ["User.Read", "Calendars.ReadWrite"]
DEFAULT_TIMEZONE = os.environ.get("MS_GRAPH_TIMEZONE", "America/Bogota")
CACHE_DIR = Path.home() / ".local" / "share" / "ms-graph-agent"
CACHE_FILE = CACHE_DIR / "token_cache.json"


class CliError(Exception):
    pass


def read_json_stdin() -> dict[str, Any]:
    if sys.stdin.isatty():
        return {}
    raw = sys.stdin.read().strip()
    if not raw:
        return {}
    try:
        return json.loads(raw)
    except json.JSONDecodeError as exc:
        raise CliError(f"invalid JSON input: {exc}") from exc


def ensure_env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise CliError(f"missing env var: {name}")
    return value


def load_cache() -> msal.SerializableTokenCache:
    cache = msal.SerializableTokenCache()
    if CACHE_FILE.exists():
        cache.deserialize(CACHE_FILE.read_text())
    return cache


def save_cache(cache: msal.SerializableTokenCache) -> None:
    if cache.has_state_changed:
        CACHE_DIR.mkdir(parents=True, exist_ok=True)
        CACHE_FILE.write_text(cache.serialize())


def build_app(cache: msal.SerializableTokenCache) -> msal.PublicClientApplication:
    client_id = ensure_env("MS_GRAPH_CLIENT_ID")
    tenant = ensure_env("MS_GRAPH_TENANT_ID")
    authority = f"https://login.microsoftonline.com/{tenant}"
    return msal.PublicClientApplication(client_id=client_id, authority=authority, token_cache=cache)


def acquire_token(interactive: bool) -> str:
    cache = load_cache()
    app = build_app(cache)
    accounts = app.get_accounts()
    result: dict[str, Any] | None = None

    if accounts:
        result = app.acquire_token_silent(DEFAULT_SCOPES, account=accounts[0])

    if not result and interactive:
        flow = app.initiate_device_flow(scopes=DEFAULT_SCOPES)
        if "user_code" not in flow:
            raise CliError(f"failed to start device flow: {json.dumps(flow)}")
        print(
            json.dumps(
                {
                    "ok": True,
                    "action": "device_login",
                    "message": flow.get("message", "Complete device login"),
                    "verification_uri": flow.get("verification_uri"),
                    "user_code": flow.get("user_code"),
                }
            ),
            flush=True,
        )
        result = app.acquire_token_by_device_flow(flow)

    save_cache(cache)

    if not result or "access_token" not in result:
        error = result.get("error_description") if result else "no cached token and interactive login disabled"
        raise CliError(f"auth failed: {error}")

    return str(result["access_token"])


def graph_request(method: str, path: str, *, params: dict[str, Any] | None = None, json_body: dict[str, Any] | None = None, interactive: bool = False) -> Any:
    token = acquire_token(interactive=interactive)
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Prefer": f'outlook.timezone="{DEFAULT_TIMEZONE}"',
    }
    response = requests.request(method, f"{GRAPH_BASE}{path}", headers=headers, params=params, json=json_body, timeout=30)
    if response.status_code >= 400:
        try:
            detail = response.json()
        except Exception:
            detail = response.text
        raise CliError(f"graph error {response.status_code}: {detail}")
    if response.status_code == 204 or not response.text:
        return {"ok": True}
    return response.json()


def parse_iso_local(value: str) -> datetime:
    try:
        dt = datetime.fromisoformat(value)
    except ValueError as exc:
        raise CliError(f"invalid datetime: {value}. Use ISO format like 2026-07-02T15:30") from exc
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=ZoneInfo(DEFAULT_TIMEZONE))
    return dt


def event_payload(data: dict[str, Any]) -> dict[str, Any]:
    subject = str(data.get("subject", "")).strip()
    start = str(data.get("start", "")).strip()
    end = str(data.get("end", "")).strip()
    if not subject or not start or not end:
        raise CliError("subject, start, and end are required")

    start_dt = parse_iso_local(start)
    end_dt = parse_iso_local(end)
    if end_dt <= start_dt:
        raise CliError("end must be after start")

    attendees = []
    for email in data.get("attendees", []) or []:
        attendees.append(
            {
                "emailAddress": {"address": str(email)},
                "type": "required",
            }
        )

    body_content = str(data.get("body", "")).strip()
    location = str(data.get("location", "")).strip()

    payload: dict[str, Any] = {
        "subject": subject,
        "start": {"dateTime": start_dt.isoformat(), "timeZone": DEFAULT_TIMEZONE},
        "end": {"dateTime": end_dt.isoformat(), "timeZone": DEFAULT_TIMEZONE},
    }
    if body_content:
        payload["body"] = {"contentType": "text", "content": body_content}
    if location:
        payload["location"] = {"displayName": location}
    if attendees:
        payload["attendees"] = attendees
    return payload


def cmd_login(_data: dict[str, Any]) -> dict[str, Any]:
    acquire_token(interactive=True)
    me = graph_request("GET", "/me", interactive=False)
    return {
        "ok": True,
        "message": "login succeeded",
        "user": {
            "displayName": me.get("displayName"),
            "userPrincipalName": me.get("userPrincipalName"),
            "id": me.get("id"),
        },
    }


def cmd_me(_data: dict[str, Any]) -> dict[str, Any]:
    me = graph_request("GET", "/me")
    return {
        "ok": True,
        "user": {
            "displayName": me.get("displayName"),
            "userPrincipalName": me.get("userPrincipalName"),
            "mail": me.get("mail"),
            "id": me.get("id"),
        },
    }


def cmd_list_events(data: dict[str, Any]) -> dict[str, Any]:
    days = int(data.get("days", 7))
    limit = min(max(int(data.get("limit", 10)), 1), 50)
    now = datetime.now(ZoneInfo(DEFAULT_TIMEZONE))
    end = now + timedelta(days=days)
    result = graph_request(
        "GET",
        "/me/calendarView",
        params={
            "startDateTime": now.isoformat(),
            "endDateTime": end.isoformat(),
            "$top": limit,
            "$orderby": "start/dateTime",
            "$select": "id,subject,organizer,start,end,location,webLink",
        },
    )
    events = []
    for item in result.get("value", []):
        events.append(
            {
                "id": item.get("id"),
                "subject": item.get("subject"),
                "start": item.get("start"),
                "end": item.get("end"),
                "location": item.get("location", {}).get("displayName"),
                "webLink": item.get("webLink"),
                "organizer": item.get("organizer", {}).get("emailAddress", {}).get("address"),
            }
        )
    return {"ok": True, "events": events}


def cmd_create_event(data: dict[str, Any]) -> dict[str, Any]:
    created = graph_request("POST", "/me/events", json_body=event_payload(data))
    return {
        "ok": True,
        "event": {
            "id": created.get("id"),
            "subject": created.get("subject"),
            "webLink": created.get("webLink"),
            "start": created.get("start"),
            "end": created.get("end"),
        },
    }


def cmd_update_event(data: dict[str, Any]) -> dict[str, Any]:
    event_id = str(data.get("id", "")).strip()
    if not event_id:
        raise CliError("id is required")
    updated = graph_request("PATCH", f"/me/events/{event_id}", json_body=event_payload(data))
    return {"ok": True, "event": updated}


def cmd_delete_event(data: dict[str, Any]) -> dict[str, Any]:
    event_id = str(data.get("id", "")).strip()
    if not event_id:
        raise CliError("id is required")
    graph_request("DELETE", f"/me/events/{event_id}")
    return {"ok": True, "deleted": event_id}


COMMANDS = {
    "login": cmd_login,
    "me": cmd_me,
    "list-events": cmd_list_events,
    "create-event": cmd_create_event,
    "update-event": cmd_update_event,
    "delete-event": cmd_delete_event,
}


def main() -> int:
    try:
        if len(sys.argv) < 2:
            raise CliError("usage: ms_graph_cli.py <command>")
        command = sys.argv[1]
        handler = COMMANDS.get(command)
        if not handler:
            raise CliError(f"unknown command: {command}")
        data = read_json_stdin()
        result = handler(data)
        print(json.dumps(result))
        return 0
    except CliError as exc:
        print(json.dumps({"ok": False, "error": str(exc)}))
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
