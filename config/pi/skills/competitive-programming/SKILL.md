---
name: competitive-programming
description: Solve competitive programming tasks in C++ using the local template and testing workflow. Use when creating, debugging, or optimizing contest/problem solutions.
---

# Competitive Programming

Use this skill when working on C++ problem-solving tasks.

## Local setup notes

This environment already includes helpful shell functions in `home.nix`:

- `tmpl <file_name>` copies `~/dotfiles/utils/template.cpp` into a new file and opens it in Neovim
- `runcpp <file.cpp>` compiles with `g++ -std=c++17 -Wall` and runs the result

The template file is:

```text
~/dotfiles/utils/template.cpp
```

## Recommended workflow

1. Restate the problem clearly.
2. Identify constraints, edge cases, and required complexity.
3. Derive the algorithm before coding.
4. State time and memory complexity.
5. Implement in C++ with clear variable names and minimal unnecessary abstractions.
6. Test against sample cases and at least a few custom edge cases.
7. If wrong or slow, inspect assumptions before rewriting everything.

## Implementation rules

- Prefer standard C++17.
- Watch for overflow; use `long long` when needed.
- Be explicit about indexing, off-by-one boundaries, and input size assumptions.
- For greedy, DP, binary search, graphs, or prefix/suffix methods, explain why the approach is correct.
- If brute force is too slow, quantify why and replace it with a complexity-appropriate approach.

## Useful commands

Create a fresh file from the template:

```bash
tmpl solution.cpp
```

Compile and run:

```bash
runcpp solution.cpp
```

Or directly:

```bash
g++ -std=c++17 -Wall solution.cpp -o solution && ./solution
```

## Debugging checklist

- Verify the input parsing matches the statement exactly.
- Check `0`/`1`-index conversions.
- Re-test smallest and largest edge cases.
- Print intermediate values only when needed, then remove debug output.
- Compare actual complexity with the problem limits.

## Done criteria

- The algorithm is explained.
- Complexity is stated.
- The implementation compiles.
- Basic tests or sample runs are performed or clearly recommended.
