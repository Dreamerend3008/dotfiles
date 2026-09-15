#define ll long long

ll binpow(ll a, ll b, ll M){
    ll r = 1;
    while(b > 0){
        if (b & 1)
                r = (r*a)%M;
        a = (a*a)%M;
        b >>= 1;
    }
    return r;
}
ll inv(ll n, ll M) {return binpow(n, M-2, M);} 

