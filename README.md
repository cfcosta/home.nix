# home.nix

Surely something will be here at some point.

## Tips and Tricks

### Cloudflare API Token

This is necessary for server configurations, as it points the domain to an
address that does not exist outside of the Tailscale network.


You'll need to create the cloudflare-api-token.age file with this content (before encrypting):

```sh
CF_DNS_API_TOKEN="your_cloudflare_api_token_here"
```

To get the Cloudflare API token:

1. Go to Cloudflare dashboard
2. Go to "My Profile" > "API Tokens"
3. Create a new token with:
   - **Template:** "Edit zone DNS"
   - **Permissions:** "Zone:DNS:Edit"
   - **Zone Resources:** Include > Specific zone > Your domain
4. Copy the token and use it in the file above
