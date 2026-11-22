# Two-device installation test

The `Install through another device` Actions workflow runs this scenario on an
Ubuntu runner using two Arch Linux containers. It can also be run locally with
Docker Engine and the Docker Compose plugin:

```bash
bash ignore/tests/install-lan/run.sh
```

Only the old device joins the external Docker network. Both devices join an
`internal: true` LAN; the new device has no external network attachment. Direct TCP
and HTTPS probes must fail both before installation and after proxy handover.
The source is mounted read-only, then copied to the new device. A shared volume
contains **public** keys and coordination markers; the devices' private homes,
GPG agents, private keys and stores are separate. The containers are not privileged
and do not mount the host Docker socket, HOME or service sockets.

The old device runs:

- a Git-over-SSH endpoint with a bare fake password store and no shell access;
- a temporary HTTP/HTTPS CONNECT proxy on port 18080;
- a permanent proxy on port 18081;
- a fake subscription URL on port 18082. Its payload describes the permanent proxy.

The store contains fake `chezmoi/bootstrap-check`, `chezmoi/ikuuu` and
`chezmoi/wyyctc` entries. The last two hold the subscription URL, not the proxy
port itself. No real account, private key, password store, GitHub token or Actions
secret is needed. Fixture passphrase programs automate only interactive UIs.

The new device starts with Bash, curl, sudo, Python (the test driver) and the base
Arch userspace. It must initially lack Git, chezmoi, paru, gopass and Mihomo. It then
executes the **real `install.sh` once**, using the temporary LAN proxy and the
`custom/core` profile:

1. Install Git and bootstrap chezmoi, run real init, build and install paru from
   source as a normal user using sudo for system package operations. No prebuilt
   paru package or package-manager stub is injected. Core AUR packages, including
   Mihomo and its dependencies, are really installed too.
2. Generate device SSH/GPG keys locally. The installer first fails SSH access and
   waits while the old device adds the public SSH key.
3. Clone the fake store; decryption must still fail. The installer waits while the
   old device verifies/signs the public key, runs the actual `add-device`, and
   pushes the re-encrypted store. The new device pulls and verifies decryption.
4. Finish installation and apply. Read the fake URL from gopass and download its
   payload **through the temporary proxy**. Start real Mihomo locally with the
   downloaded permanent upstream port.
5. Terminate the temporary proxy process, including existing tunnels. Assert its
   listener and proxy requests fail. Direct Internet access must still fail.
6. Through local Mihomo and the permanent upstream, fetch an HTTPS page, download
   and install the small official `tree` package, run ordinary apply, and fetch
   another HTTPS page. Assert old-device logs show subscription delivery through
   the temporary proxy and HTTPS connections through the permanent proxy.

Production `.chezmoiexternal.toml` declarations are disabled in the disposable
source, as required by repository test policy. The Mihomo connection test uses a
minimal fixture config with the downloaded proxy, not the full production Geo and
rule-provider configuration. Desktop startup, systemd user services and optional
plugin initialization are excluded. This is an Arch test; macOS still needs its
own runner and cannot run inside these Linux containers.

The Docker image build prepares the baseline environments with Internet access.
**After containers start, all new-device downloads and builds must use the old
device.** Dependencies are fetched from the actual Arch/AUR/upstream services, so
upstream failures intentionally fail this end-to-end test. Expect real Rust/Go
build time and several GiB of disk use; the job has a 90-minute timeout and uses
two compiler workers. Build directories are on the container filesystem, not a
tmpfs. There is no build cache that could conceal paru compilation.

Logs appear in `artifacts/` (gitignored) and are uploaded by Actions on failure or
success. Only explicit `*.log` files are uploaded; no HOME, keyring, store, exchange
volume or container filesystem is exported. `run.sh` removes the two containers
and the exchange volume on exit, including failure. The read-only repository and
host package databases are not changed. The test uses subnet `172.30.247.0/24`;
change the fixture addresses together if it overlaps a local Docker network.

The loopback-only control checks can be run without Docker or Internet:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 ignore/tests/install-lan/test-controls.py
```

These check HTTP forwarding, CONNECT tunnels, the subscription payload and closing
established tunnels when the temporary proxy dies. They do not replace the real
Docker installation scenario.
