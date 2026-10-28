#!/bin/bash
export HOME=/root PATH=/root/bin-wrappers:/root/.opencode/bin:/root/.bun/bin:/usr/local/bin:/usr/bin:/bin:/sbin TMPDIR=/tmp
MODE="${1:-repair}"; ok(){ echo "  ✔ $1"; }; bad(){ echo "  ✗ $1"; }; fix(){ echo "  🔧 $1"; }
V(){ [ "$MODE" = check ] && return 1 || return 0; }

echo "  -- apt/dpkg --"
if apt-get check >/dev/null 2>&1; then ok "apt SANO"
else
  bad "apt/dpkg ROTO"
  if V; then
    # fix conocido: machine-id de systemd falla en chroot
    B=/usr/bin/systemd-machine-id-setup
    if [ -f "$B" ]; then cp -f "$B" "$B.real" 2>/dev/null; printf '#!/bin/sh\n[ -s /etc/machine-id ] || cat /proc/sys/kernel/random/uuid|tr -d - >/etc/machine-id\nexit 0\n' >"$B"; chmod 755 "$B"; fi
    printf '#!/bin/sh\nexit 101\n' >/usr/sbin/policy-rc.d; chmod 755 /usr/sbin/policy-rc.d
    DEBIAN_FRONTEND=noninteractive dpkg --configure -a >/dev/null 2>&1
    [ -f "$B.real" ] && mv -f "$B.real" "$B"
    apt-get check >/dev/null 2>&1 && fix "apt reparado (machine-id/systemd)" || bad "apt sigue roto; revisar a mano"
  fi
fi

echo "  -- red del chroot --"
getent hosts kali.org >/dev/null 2>&1 && ok "DNS/internet OK" || bad "sin internet (revisa WiFi de Android arriba)"

echo "  -- /dev/shm (apps graficas) --"
[ -d /dev/shm ] && ok "/dev/shm montado" || { bad "/dev/shm falta"; V && fix "lo monta bootkali al entrar"; }

echo "  -- opencode / TUIs modernas --"
if [ -x /root/bin-wrappers/opencode ]; then ok "wrapper opencode presente (TUI protegida con tmux)"
else bad "wrapper opencode ausente"; fi
command -v tmux >/dev/null && ok "tmux OK" || { bad "tmux falta"; V && { DEBIAN_FRONTEND=noninteractive apt-get install -y tmux >/dev/null 2>&1 && fix "tmux instalado"; }; }

echo "  -- herramientas clave --"
command -v nmap >/dev/null && ok "nmap" || bad "nmap falta"
# metasploit: el bucle de symlinks de llvm que ya arreglamos
if [ -L /usr/lib/llvm-21/build/Debug+Asserts ] && [ "$(readlink /usr/lib/llvm-21/build/Debug+Asserts)" = ".." ]; then
  bad "llvm symlink recursivo (rompe metasploit)"
  V && { mkdir -p /usr/lib/llvm-21/.emptybuild; ln -sf /usr/lib/llvm-21/.emptybuild /usr/lib/llvm-21/build/Debug+Asserts; ln -sf /usr/lib/llvm-21/.emptybuild /usr/lib/llvm-21/build/Release 2>/dev/null; fix "llvm reparado (metasploit)"; }
else command -v msfconsole >/dev/null && ok "metasploit" || echo "  · metasploit no instalado"; fi
