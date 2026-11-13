# Hearthside Home Library

A responsive public book catalog with search, alphabetical/date sorting, book covers, and protected admin create/edit/delete. The front end is one self-contained `index.html`; Netlify serves it and runs the small server-side function needed to protect custom username/password authentication and the Supabase service-role key.

## 1. Create the Supabase data store

1. Create a Supabase project.
2. Open **SQL Editor → New query**, paste all of `supabase-setup.sql`, then click **Run**. This creates the public read-only catalog table and a public-read `book-covers` Storage bucket. Client-side insert, update, delete, and Storage upload policies are intentionally absent.
3. In **Project Settings → API**, copy the **Project URL** and the **publishable/anon key**. The public key is designed to be exposed in a browser; row-level security limits it to catalog reads.

## 2. Set the two public browser values

Edit the two constants near the top of the inline `<script>` in `index.html`:

```js
const SUPABASE_URL='https://YOUR_PROJECT_REF.supabase.co', SUPABASE_ANON_KEY='YOUR_PUBLISHABLE_OR_ANON_KEY';
```

These are the only Supabase values that belong in the HTML. **Never put the service-role key, password, or token-signing secret in `index.html`.**

## 3. Create a bcrypt password hash

On a computer with Node.js 20 or newer, in this project folder, run:

```sh
npm install
node --input-type=module -e "import bcrypt from 'bcryptjs'; console.log(await bcrypt.hash(process.argv[1], 12))" "REPLACE_WITH_A_LONG_UNIQUE_PASSWORD"
```

Copy the resulting `$2...` hash. Use a strong, unique password and avoid placing it in shared terminal history; you can instead run the same command in a private local terminal. The password itself is only used to make the hash and is never deployed.

## 4. Deploy to Netlify

1. Put the contents of this `outputs` folder in a Git repository, then in Netlify choose **Add new site → Import an existing project** and connect that repository. Alternatively, drag-and-drop deploys do **not** build Functions or install dependencies, so use a Git-connected site for the admin feature.
2. In the Netlify site, open **Project configuration → Environment variables** and add these five values for the deploy contexts you use:

   | Name | Value |
   |---|---|
   | `SUPABASE_URL` | The same project URL used in `index.html` |
   | `SUPABASE_SERVICE_ROLE_KEY` | Supabase **service_role** secret key from Project Settings → API; server-side only |
   | `ADMIN_USERNAME` | The exact username you choose |
   | `ADMIN_PASSWORD_HASH` | The bcrypt hash from step 3, including its `$2...` prefix |
   | `ADMIN_TOKEN_SECRET` | A fresh random secret of at least 32 bytes |

   Generate the token secret locally with `node -e "console.log(require('crypto').randomBytes(48).toString('base64url'))"`. Add it as a Netlify value; do not commit it or put it in the HTML. Mark sensitive values as secret in Netlify where that option is available.
3. Set the build command to `npm install` and publish directory to `.` (Netlify also reads these from `netlify.toml`). Node functions are in `netlify/functions`.
4. Trigger **Deploy site** after setting the variables. Netlify needs a fresh deploy to apply changed function environment variables.
5. Open the deployed site, check public book browsing, then choose **Add books** and sign in with `ADMIN_USERNAME` and the original password used to create its hash.

## Local preview

Use Node.js 20+, run `npm install`, set the five server environment variables in your local Netlify environment, and run `npx netlify dev`. For example, with a local `.env` file, use the same variable names shown above. Keep `.env` out of version control. Put the public URL and anon key in `index.html` first.

## Security and behavior

- The admin password is checked server-side with bcrypt. A signed, eight-hour bearer token is held in browser `sessionStorage` and is cleared when the user logs out or the tab session ends.
- The Netlify Function is the only writer. It uses `SUPABASE_SERVICE_ROLE_KEY` only on the server, checks a signed token on every admin request, and validates book fields and cover uploads.
- Public visitors can read the catalog and cover files. RLS and Storage policies give browser clients no write access.
- The app offers live search by title/author/location, A–Z and oldest/newest sorting, responsive cards, and admin add/edit/delete. Book names are required; author, shelf, and cover are optional.
- Cover files are resized to WebP in the browser, capped at 1400px and 3.75 MB for upload. Replacing or deleting a book removes its previous cover file.
- The UI loads DM Sans and Playfair Display from Google Fonts; if fonts are unavailable, system fallbacks are used.

This is a single-admin home library suitable for a personal collection. For a public high-traffic service, add edge rate limiting to `/api/admin/login` in Netlify or an upstream WAF; serverless function instances do not share reliable in-memory rate-limit state.
