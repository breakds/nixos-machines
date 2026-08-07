# The Story of Authorization with Examples

Or, how to re-invent OAuth and OIDC.

## Story 

Let's say someone wants to track the expenses they make on an online shopping platform, say Amason. To do the tracking, they want to use a ledger application, say iLedger.

For the tracking to stay up to date - so that iLedger can remind the user in time - iLedger needs to pull the list of transactions from Amason regularly, say every 15 minutes.

That gives us three parties: the **user**, who owns the data; **Amason**, which holds it; and **iLedger**, which wants to read it. They need an arrangement that leaves all three satisfied.

## Journey

The simplest idea is to have the user copy the transaction data into iLedger by hand every 15 minutes, or whenever they remember. Obviously a bad idea.

### Sharing Username and Password

Next idea: what if the user simply gives their Amason username and password to iLedger? Then, whenever iLedger wants transaction data, it can log into Amason on the user's behalf and fetch it.

There are quite a few threat models.

- The password has to be stored **reversibly** in iLedger's database - as plaintext, or encrypted with a key iLedger also holds. This is not a matter of iLedger being sloppy; it is forced. Amason can store a one-way hash of the password, because Amason only ever needs to *check* a password. iLedger needs to *replay* it, so hashing is not available to it. If iLedger is compromised (or its database, or some cloud service it depends on), the password leaks together with the username, which is usually an email.
- Even if iLedger has good intention, an evil hacker that hacks iLedger, or an evil employee in iLedger can try to access information other than transaction from the user's Amason account. For example, address and credit card information, or even change the password.
- It is not obvious to the user who accessed their Amason account.
- There is no way to revoke iLedger's access on its own. The only lever is changing the password, and that lever is global: it revokes access for *every* other app the user shared the password with, and logs the user out of all their own sessions too. This is not merely tedious - there is exactly one kill switch and it destroys everything at once.
- Two-factor authentication breaks the scheme entirely. If Amason requires a second factor, iLedger simply cannot complete the login with a password alone. More generally, any improvement Amason makes to how it authenticates people - 2FA, passkeys, hardware keys, step-up challenges - breaks every integration that was logging in on a user's behalf.
- Users reuse passwords. The blast radius of a leak from iLedger is not limited to Amason; it extends to every other site where the user used the same password.

In the end, the user has good reason not to trust this approach.

### API Key

In this setting, the user logs into Amason, asks Amason to mint an API key, and hands that key to iLedger. From then on, iLedger can call Amason's API every 15 minutes to pull the transactions, presenting the key as a bearer credential.

Two of the objections from the previous section have straightforward answers here.

- *What stops iLedger from calling APIs beyond transactions?* Amason can attach a **scope** to each key it mints, so that a key is restricted to "read transaction data only". A key that tries anything else is refused.
- *What if the user suspects iLedger is compromised, or that the key has leaked?* Amason can let the user **revoke** that one key. Nothing else the user has granted is affected, and their own password and sessions are untouched.

This is actually quite good, and at this point all three parties are mostly satisfied. It is worth noticing what changed and what did not: scope and revocation fixed the security problems, but the user is still moving a secret around by hand.

That is where the remaining problems are - scalability and observability. Once the user has minted a handful of keys on Amason, they have to name each one carefully just to know which is which when the time comes to revoke one. And copying the key, pasting it, storing it somewhere, and picking the right scope out of a possibly long list of permissions are all tedious steps that are easy to get wrong.

So the API key is a good start. What needs improving is not the key itself, but the way it gets handed over.

### Improving the API Key Granting User Experience

Imagine a better way to grant an API key.

- iLedger drafts a structured message that says, roughly: *please grant me an API key for this user, with this scope (read transaction data), and once it is minted, deliver it to me here* - where "here" is a callback URL that iLedger supplies.
- The user logs into Amason and hands it that message. Amason explains what is being asked for and requests the user's confirmation. Once the user confirms, Amason mints the key and delivers it to iLedger at the callback URL.

Amason then records an entry in a "granted" list: one API key, issued to iLedger, scoped to transactions. The user never has to see the key at all, but when they want to revoke it or change its scope, they can find it in that list and do so.

Better still: if Amason's granting page lives at a predictable URL, iLedger can put a button in its own interface that simply sends the user there. If the user is not logged into Amason yet, they log in at that point. The whole exchange becomes smooth, and the user never touches the key.

### What Is Still Broken

That scheme is a large improvement and it is close to the real answer. But read it again as an attacker rather than as a user, and four problems appear.

**Problem 1: the key travels through the browser.**

A callback URL is a redirect, which means the key is placed into a URL, and that URL is handled by the user's browser. A URL is not a private place:

- it is written into the browser history
- it can leak to third parties in the `Referer` header of whatever the landing page loads next
- it is written into iLedger's own web server access log
- it is visible to every proxy and TLS-terminating load balancer between the browser and iLedger

We took care never to let the user copy and paste the key by hand, and then handed it to the one transport that is guaranteed to be logged in several places.

**Problem 2: Amason has no idea who it is really talking to.**

In our scheme iLedger "drafts a structured message" naming a scope and a callback URL. Nothing about that message proves it came from iLedger. An attacker can draft their own:

```
client=iLedger&scope=transactions&callback=https://evil.example/collect
```

Amason will faithfully show the user *"iLedger would like to read your transactions"*, the user approves in good faith, and Amason delivers a perfectly valid key to the attacker's callback URL. The consent screen was honest about the scope and lied about the recipient, and Amason had no way to know.

**Problem 3: iLedger cannot tell whether an arriving key belongs to the user who started the flow.**

iLedger's callback endpoint accepts whatever shows up at it. So an attacker can start their *own* grant flow at Amason, intercept the resulting callback URL before their browser follows it, and get the victim to visit that URL instead. iLedger then attaches the **attacker's** Amason account to the **victim's** iLedger account. Every transaction the victim later records flows into an account the attacker controls. Note the direction here: this attack does not steal the victim's data, it plants the attacker's data on the victim - which is easy to miss when reasoning only about theft.

**Problem 4: the key never expires.**

Once granted it works forever. If it leaks through any of the channels above, the leak is permanent until a human notices and revokes it. Revocation exists, but it only helps if somebody realizes something is wrong. Nothing about the system limits the damage on its own.

### Reaching OAuth 2.0

Each problem has a fix, and the four fixes together are essentially OAuth 2.0.

#### Fix for Problem 2: register iLedger ahead of time

Before any user is involved, iLedger registers itself with Amason once. Amason issues it:

- a **client id** - a public name, safe to put in a URL
- a **client secret** - private, known only to Amason and iLedger's server
- an allowlist of **callback URLs** that Amason is willing to deliver to

Now the earlier attack fails. The attacker can put `client_id=iLedger` in their request, but they must also supply a callback URL, and Amason will only accept one from iLedger's registered allowlist. The match must be exact, not a prefix - a lot of real-world vulnerabilities have come from servers that accepted `https://iledger.example/callback.evil.com` because it started with the right characters.

Registration also makes the consent screen trustworthy. Amason can now say "iLedger" and mean it, because it verified the client id against its own records.

#### Fix for Problem 1: send a code through the browser, not the key

This is the central idea, and it is worth naming the two very different paths a message can take:

| | Front channel | Back channel |
|---|---|---|
| Route | through the user's browser, via redirects | iLedger's server directly to Amason's server |
| Who can see it | user, history, logs, proxies, `Referer` | nobody else |
| Can the user tamper with it | yes | no |

The key must never touch the front channel. But *something* has to come back through the browser, because the browser is the only thing that has just talked to both parties.

So Amason sends back a **code** instead: a short-lived, single-use string that is worth nothing on its own. iLedger's server then makes a direct back-channel request to Amason:

> Here is the code I just received. Here is my client id and my client secret. Give me the key.

Amason checks that the code is unused and unexpired, that it was issued to this exact client, and that the secret matches. Only then does it return the key - over a private server-to-server connection that never touches the browser.

Now look at what a leaked code is worth. It expires in seconds. It can be redeemed once, so if the real iLedger already used it, it is dead. And redeeming it requires iLedger's client secret, which an attacker does not have. The thing we allowed to leak has been made nearly worthless, and the thing that matters never went anywhere it could leak.

#### Fix for Problem 3: bind the response to the request

Two separate bindings are needed, because there are two separate things to prove.

**Prove the response belongs to this user's session.** When iLedger starts the flow it generates a random value called **state**, remembers it against the user's session, and includes it in the redirect. Amason echoes it back unchanged on the callback. If a code arrives with a state that iLedger did not issue for this session, iLedger throws it away. That defeats the injection attack above.

**Prove the redeemer is whoever started the flow.** iLedger generates a second random secret, keeps it, and sends only its hash in the initial redirect. When it later redeems the code, it presents the original secret. Amason hashes it and compares. Only the party that began the flow can finish it.

That second mechanism is called **PKCE** (Proof Key for Code Exchange). It was invented for mobile apps and single-page apps, which cannot keep a client secret - anything shipped to a user's device is readable by that user. Today it is recommended for every client, secret or not, because it also protects against a code being stolen in transit.

#### Fix for Problem 4: make the key expire, and add a way to renew it

Split the single immortal key into two things:

- an **access token**, which is what actually gets sent to Amason's API, and which expires quickly - minutes, not months
- a **refresh token**, which is long-lived, is never sent to the API, and travels only on the back channel; its only purpose is to be exchanged for a fresh access token

This is what makes our original scenario work. iLedger wants to poll every 15 minutes, potentially for years. We are not going to ask the user to re-approve anything on that cadence. So iLedger holds the refresh token, and whenever its access token expires it quietly exchanges the refresh token for a new one, with no user involvement.

The tradeoff is worth stating plainly, because it explains a lot of OAuth's shape. A short lifetime is what you use *instead of* being able to revoke instantly. A leaked access token is bad for fifteen minutes rather than forever. And because the refresh token never rides the front channel and never goes to the API, it is exposed in far fewer places than the access token it replaces.

#### Putting it together

```
1. Browser -> iLedger        user clicks "Connect Amason"

2. iLedger -> Browser        redirect to Amason:
                               client_id, scope=transactions,
                               redirect_uri, state, code_challenge

3. Amason  <-> User          Amason authenticates the user however it
                             likes - password, 2FA, passkey. iLedger
                             is not part of this conversation and does
                             not need to know how it works.

4. Amason  -> User           "iLedger would like to read your
                              transactions. Allow?"

5. Amason  -> Browser        redirect back to redirect_uri:
                               code, state

     ---- front channel ends here -------------------------
     ---- back channel begins -----------------------------

6. iLedger -> Amason         POST: code, client_id, client_secret,
                                   code_verifier

7. Amason  -> iLedger        { access_token, expires_in, refresh_token }

8. iLedger -> Amason API     Authorization: Bearer <access_token>
                             (every 15 minutes, until it expires,
                              then use the refresh token and continue)
```

Step 3 deserves a second look, because it quietly solves the 2FA problem from the password section. The user authenticates *at Amason*, in Amason's own interface. iLedger never sees a credential and never needs to know what kind of credential it was. Amason can add hardware keys tomorrow and no integration breaks.

#### Naming what we built

Everything above has a standard name. The story terms map like this:

| Our story | Standard term |
|---|---|
| the user | resource owner |
| iLedger | client |
| the message iLedger drafts | authorization request |
| the predictable Amason URL | authorization endpoint |
| the callback URL | redirect URI |
| the short-lived single-use string | authorization code |
| the back-channel exchange | token endpoint |
| the "granted" list on Amason | consent / grant management |
| what the key is allowed to do | scope |

The specific sequence we arrived at - redirect out, code back, redeem on the back channel - is called the **authorization code flow**, and it is the one that matters. Amason itself has a standard name too, but it turns out Amason is doing two quite different jobs here, so that is worth pulling apart separately.

### Amason Is Actually Two Things

The story has treated Amason as one system. That was fine while there was a single API and a single client, but neither stays true for long.

Amason does not only serve transactions. It also has an address book, an order history, a wishlist, a returns API. And iLedger is not its only integration - there are tax tools, budgeting apps, shipping trackers, dozens of them.

So ask an uncomfortable question about the previous section: *which part of Amason implements all that machinery?* Does the transactions API host its own consent screen, keep its own registry of clients, mint its own codes, run its own token endpoint, and handle its own refresh logic? And then the address book API implements the whole thing again, separately?

Obviously not. Notice that none of that machinery is about transactions. It is entirely about *who is asking, what they are allowed to do, and whether the user agreed* - which is the same question no matter which API is being called. So we factor it out:

- One component authenticates the user, shows the consent screen, keeps the registry of clients, and mints and refreshes tokens. This is the **authorization server**.
- Every API becomes something much simpler. It receives a request carrying a token, checks that the token is valid and has the right scope, and serves the data. This is a **resource server**.

The naming table from earlier can now be completed:

| Our story | Standard term |
|---|---|
| the part of Amason that logs the user in, shows the consent screen, and mints keys | authorization server |
| the part of Amason that actually serves transaction data | resource server |

This is a bigger change than it looks, and four things fall out of it.

**Resource servers hold no secrets.** A resource server never sees a password, never stores a credential, and has no credential database at all. Its entire job is to validate a token - by introspection if the token is opaque, or by checking a signature if it is a JWT. An API that was never given credentials cannot leak them, no matter how badly it is written.

**Authentication becomes one component's problem.** When Amason wants to add passkeys, or require 2FA for high-value accounts, or support corporate SSO, it changes the authorization server and nothing else. Not one resource server needs to know, because no resource server was ever involved in authenticating anybody.

**There is exactly one place to look.** One list of every grant the user has issued, across every API and every client. One place to revoke.

**New APIs are cheap.** A new Amason API does not implement any of this. It validates tokens and serves data, and it inherits consent, scoping, revocation, and the whole client registry for free.

And there is a fifth consequence, which is really the point of everything above: **the authorization server and the resource server no longer have to be the same organization.** Once the boundary between them is a well-specified protocol rather than an internal function call, an API written by someone who has never heard of your authorization server can still accept its tokens. That is the moment this stops being a clever Amason feature and becomes an ecosystem.

It is also the moment the authorization server becomes a product you can just install. Keycloak and Authentik are exactly this box: they authenticate users, keep the client registry, show consent, and mint tokens - and they know nothing about whatever applications you point at them.

### Extra Details and Optional Features

Everything up to here is the load-bearing structure. The rest is detail you will meet in real systems.

#### What does the access token actually look like?

The design above never said. That is deliberate - it does not matter to the story, and the standard does not mandate a format. There are two families:

- **Opaque tokens.** Random strings, meaningless on their own, exactly like the API key we started with. The resource server looks each one up to find out what it means. Easy to revoke - delete the row and it dies instantly. Costs a lookup per request.
- **Signed tokens (JWT).** The permissions are written *inside* the token as JSON, and the authorization server signs it. The resource server can verify the signature and read the contents without asking anyone. No lookup, no shared database. But the token is valid until it expires, and there is no clean way to kill it early.

This is the same revocable-versus-stateless tradeoff throughout, and it is why signed tokens are always given short lifetimes: the expiry is standing in for the revocation you gave up. Note also that a JWT is *signed*, not encrypted - anyone holding one can read every field in it, so nothing secret goes inside.

If a resource server wants to accept opaque tokens without sharing a database with the authorization server, there is a standard endpoint for asking "is this token still good, and what does it mean?" It is called **token introspection**.

#### Other ways to get a token

The authorization code flow assumes a human with a browser. Not every situation has one, so there are other **grant types**:

- **Client credentials** - no user at all. A service sends its client id and secret and receives an access token. This is machine-to-machine, and it is essentially an API key exchanged for a short-lived token. Use it for backend services talking to each other, where there is no user to consent on behalf of.
- **Device code** - for televisions, CLIs, and anything without a usable browser. The device shows "go to example.com/device and enter WXYZ-1234", and the user completes the approval on their phone while the device polls.
- **Refresh** - exchange a refresh token for a new access token, as described above.

Two grant types exist in the original specification and are now deprecated, and both should look familiar:

- **Implicit grant** - the authorization server returns the access token directly in the redirect. That is exactly the design we sketched in *Improving the API Key Granting User Experience*, and exactly the one Problem 1 shot down. It was removed for precisely that reason.
- **Resource owner password credentials** - the client collects the user's username and password and posts them to the token endpoint. That is the password anti-pattern from the beginning of this document, standardized. Also removed.

Both of the designs we rejected on our way here were once real, blessed parts of the specification. The history of OAuth is largely the history of learning why they were wrong.

#### What this does *not* solve

One thing is conspicuously absent. At the end of the whole flow, iLedger holds a token that lets it read transactions - but it still does not know **who the user is**. It never asked, and nothing in the exchange told it. The access token is addressed to the resource server, not to iLedger; iLedger is not supposed to open it and in the opaque case cannot.

That is not an oversight. This entire document has been about *authorization* - what an app is permitted to do. It has said nothing about *authentication* - who someone is. They are genuinely different questions, and the fact that "Log in with Google" is built on this machinery makes them very easy to confuse.

Getting from here to "iLedger knows exactly which person this is" needs one more layer on top, which is the subject of the next part.

### Who Is the User?

Let's push on that gap, because it is not a small one.

iLedger now has everything it asked for. It can pull transactions every 15 minutes, forever, without ever having seen a password. But iLedger is a ledger application - it has its own accounts, its own settings, its own saved reports. It needs to know *which of its users* this data belongs to. And at the end of the entire flow, it does not know.

This is not an oversight in our design. Everything up to this point has been about **authorization**: what an application is permitted to do. Nothing has been about **authentication**: who somebody is. They feel like the same topic and they are not.

#### The tempting wrong answer

The obvious shortcut: *the token works, so the user must be who they say they are.* iLedger calls some "tell me about the current user" API with the access token, gets back an answer, and logs that person in.

This is broken, and it is worth seeing exactly why, because the reason is the same "who is this addressed to?" question from the two-channel discussion.

The access token is a **bearer** credential addressed to the **resource server**. It carries no statement about which client obtained it, and in the opaque case iLedger cannot read it at all. So "I am holding a working token" means only "somebody, at some point, obtained a valid token." It does not mean "the person in front of me obtained it."

Now the attack. I write a small app - a shipping tracker, say - and register it with Amason like any other client. You use it, and you legitimately authorize it, so I now hold a valid access token for your Amason account. I take that token and inject it into iLedger's callback. iLedger asks Amason "who does this token belong to?", Amason truthfully answers "that user", and iLedger logs *me* into *your* iLedger account.

Nothing was forged and nothing was stolen. I simply reused a token that was legitimately issued to me, in a place that never checked whether it was issued *for* it. A bearer token proves possession, never identity.

#### The fix: a token addressed to the client

The problem is a missing recipient, so the fix is a second token that has one.

Alongside the access token, the authorization server issues an **ID token**. Two properties make it work:

- It is **always a JWT**, signed by the authorization server. It has to be readable, because the client is the intended consumer. (This is also the clean answer to a question from the previous section: the access token *may* be opaque because only the resource server needs to understand it. The ID token may never be, because the client must.)
- It carries an **audience** field, `aud`, set to the requesting client's client id. The client verifies that `aud` matches its own client id and rejects the token otherwise.

That single check kills the attack. My shipping tracker's ID token has `aud: shipping-tracker`. When I inject it into iLedger, iLedger sees an audience that is not its own client id and throws it away. The token was minted for me, it says so, and it cannot be laundered into a different application.

This layer on top of OAuth 2.0 is **OpenID Connect**, usually written OIDC.

#### What is inside an ID token

A JWT is signed but not encrypted, so anyone holding one can read every field. The standard claims:

| Claim | Meaning |
|---|---|
| `iss` | issuer - which authorization server minted this. Must match the one you configured. |
| `sub` | subject - a stable, unique identifier for the user within that issuer |
| `aud` | audience - the client id this token was minted for |
| `exp` / `iat` | expiry and issue time |
| `nonce` | echoes a random value the client sent in the authorization request |

`nonce` is worth distinguishing from `state`, since they look similar and do different jobs. `state` protects the *redirect*, tying the callback to the browser session that started it. `nonce` protects the *ID token*, proving it was minted in response to this specific request rather than replayed from an older one.

Request additional scopes and you get additional claims: `profile` brings `name`, `preferred_username`, `picture`; `email` brings `email` and `email_verified`. Most authorization servers can also be configured to include group or role membership, which is how you end up doing authorization decisions - "is this person in the `admins` group?" - on top of an identity layer.

#### Use `sub`, not email

This deserves its own heading because getting it wrong is common and the consequences are bad.

When an application links an OIDC identity to a local account, it must key on `iss` plus `sub`. Not email. Two reasons:

**Emails change.** A user updates their address at the authorization server, logs into the application, and the application - which stored `alice@old.example` - sees a stranger. Best case it creates a duplicate account; worst case the original is orphaned with no way back in.

**Emails can be claimed.** If an authorization server does not verify email addresses, anyone can register an account claiming `admin@yourdomain.example`. An application that matches on email will happily hand over the existing account. This is a genuine account-takeover path, which is why `email_verified` exists and why it should be checked whenever email is used for anything that matters.

`sub` is opaque, stable, and unique per issuer. It is ugly in a database and it is the correct key. Treat `email` and `name` as display attributes that may change at any time.

#### How little was actually added

Here is the pleasant surprise. After all that machinery, the difference between an OAuth 2.0 request and an OIDC request is:

```
scope=transactions            ->    scope=openid transactions
```

The literal scope value `openid` is what turns one into the other. The flow is unchanged - same redirect, same code, same back-channel exchange - and the token response simply gains one extra field:

```
{ "access_token": "...", "expires_in": 900,
  "refresh_token": "...", "id_token": "eyJhbGci..." }   <- new
```

OIDC really is a thin layer. It adds an identity token, a few standard claims, and the rules for validating them. Everything underneath is the flow we already built.

#### Discovery: why configuration is one URL

One last piece, and it is the one you will actually appreciate in practice.

An OIDC provider publishes a metadata document at a fixed, predictable path:

```
https://auth.example.com/.well-known/openid-configuration
```

That returns JSON listing everything a client needs: the authorization endpoint, the token endpoint, the userinfo endpoint, which scopes and signing algorithms are supported, and a `jwks_uri`.

That last one points at the provider's **public keys**. A client fetches them, caches them, and uses them to verify ID token signatures. Because each key carries an identifier and the ID token names which key signed it, the provider can rotate keys without breaking anyone - clients just fetch the new set.

This is why configuring an OIDC-aware application takes three values rather than ten: an issuer URL, a client id, and a client secret. The application derives every endpoint and every key from the discovery document. That is not a convenience feature bolted on afterwards; it is what makes it realistic to point twenty unrelated applications at one authorization server.

There is also a **userinfo endpoint**, which returns claims when called with an access token. Having both can seem redundant, but they answer different questions: the ID token is a snapshot from the moment of login, available immediately with no network call, while userinfo is current and can be queried later. Use the ID token to establish who logged in; use userinfo when you need fresh attributes afterwards.

## Where This Leaves Us

Stepping back, the whole path was a sequence of small repairs:

1. Copy data by hand. Unusable.
2. Share the password. Every problem at once: no scope, no revocation, no attribution, and it breaks the moment real authentication is introduced.
3. Mint an API key with a scope, revocable on its own. The security problems are genuinely solved - but a human is still carrying a secret around.
4. Have the application request the key and have it delivered automatically. Better, but the key rides through the browser, nobody has verified the application, and nothing links the response to the request.
5. Register the client, send a single-use code through the browser instead of the key, redeem it on a private back channel, bind everything with `state` and PKCE, and give the credential an expiry with a refresh path. This is **OAuth 2.0**.
6. Notice that one component is doing all the user-facing work for every API, and split it out. This is the **authorization server** and the **resource server**.
7. Notice that none of it says who the user is, and add a token addressed to the client to answer that. This is **OpenID Connect**.

Every step fixed something concrete from the step before it. Nothing here was designed in one sitting, and the two designs the specification later deprecated - implicit and password grants - are exactly the two intermediate stages we ourselves rejected on the way through.

Which also means the vocabulary is no longer arbitrary. An issuer URL, a client id and secret, a redirect URI, scopes, an `aud` claim, a JWKS endpoint - each one exists because something specific went wrong without it.
