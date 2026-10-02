# Windows UI Automation VM Testing

This repository can run Windows UI Automation qualification on a Linux host through
QEMU when a licensed or evaluation Windows image is available.

## Image

Use the official Windows 11 Enterprise Evaluation ISO from Microsoft Evaluation
Center. The currently prepared local path is:

```text
vm/windows11/Win11_Enterprise_Eval_25H2_en-us.iso
```

The ISO is intentionally ignored by git.

## Local VM Layout

Use local workspace paths for all VM state:

```text
vm/windows11/a11y-win11.qcow2
vm/windows11/OVMF_VARS.fd
vm/windows11/tpm/
vm/windows11/logs/
```

The host should provide:

```text
/usr/bin/qemu-system-x86_64
/usr/bin/qemu-img
/usr/bin/swtpm
/usr/share/OVMF/OVMF_CODE_4M.fd
/usr/share/OVMF/OVMF_VARS_4M.fd
```

Windows 11 needs UEFI and normally needs TPM. Use `swtpm` and OVMF for a normal
install path.

## Prepared VM

The local VM has been installed and completed through OOBE as:

```text
Edition: Windows 11 Enterprise Evaluation
Build:   26200.6584, 25H2 evaluation media
User:    a11y
Password: empty
Display: VNC localhost port 5911
RDP:     localhost port 53389 forwarded to guest 3389, guest service not enabled
WinRM:   localhost port 55985 forwarded to guest 5985, guest service not enabled
```

The VM was installed offline during OOBE. Do not let a fresh OOBE session reach
the network before the local account exists: Windows can switch into a cloud
work-or-school enrollment flow, which is not useful for deterministic UIA tests.

The QEMU SMBIOS UUID used for the prepared VM is:

```text
4b347f04-4ba8-4d18-890d-7e35579018df
```

## Host Permission

`/dev/kvm` is preferred for practical performance. If the current user is not in
the `kvm` group, QEMU may need either adjusted host permissions or a TCG fallback.
The TCG fallback is suitable for boot validation but is usually too slow for
productive native UIA qualification.

## Current Launch Shape

Start the TPM emulator first:

```sh
swtpm socket --tpmstate dir="$PWD/vm/windows11/tpm" \
  --ctrl type=unixio,path="$PWD/vm/windows11/tpm/swtpm-sock" \
  --tpm2 --daemon
```

Then launch QEMU with secure-boot OVMF, the prepared disk, VNC, and loopback-only
network forwards. The forwards are intentionally not enough by themselves:
Windows guest-side RDP/WinRM services and firewall policy must be configured
explicitly before remote automation is available.

```sh
qemu-system-x86_64 -daemonize \
  -name a11y-win11-uia \
  -machine q35 \
  -accel kvm -accel tcg,thread=multi \
  -cpu max -m 8192 -smp 4 \
  -uuid 4b347f04-4ba8-4d18-890d-7e35579018df \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.secboot.fd \
  -drive if=pflash,format=raw,file="$PWD/vm/windows11/OVMF_VARS.fd" \
  -drive file="$PWD/vm/windows11/a11y-win11.qcow2",if=none,id=drive0,format=qcow2,cache=writeback \
  -device ich9-ahci,id=sata \
  -device ide-hd,drive=drive0,bus=sata.0 \
  -drive file="$PWD/vm/windows11/Win11_Enterprise_Eval_25H2_en-us.iso",media=cdrom,readonly=on,if=none,id=cd0 \
  -device ide-cd,drive=cd0,bus=sata.1 \
  -chardev socket,id=chrtpm,path="$PWD/vm/windows11/tpm/swtpm-sock" \
  -tpmdev emulator,id=tpm0,chardev=chrtpm \
  -device tpm-tis,tpmdev=tpm0 \
  -device qemu-xhci -device usb-tablet \
  -netdev user,id=n0,hostfwd=tcp:127.0.0.1:53389-:3389,hostfwd=tcp:127.0.0.1:55985-:5985 \
  -device e1000,netdev=n0 \
  -vnc 127.0.0.1:11 \
  -monitor unix:"$PWD/vm/windows11/monitor.sock",server,nowait \
  -D "$PWD/vm/windows11/logs/qemu.log"
```

Current safe access is VNC only:

```text
127.0.0.1:5911
```

## Host VM Probe

Use the Ada test tool `tests/bin/windows_vm_probe` to record host-side VM
readiness before attempting public UIA traversal from the guest. The JSON mode
uses the schema `org.a11y.windows_uia_vm_probe.v1` and records:

```text
tests/bin/windows_vm_probe --json
```

The probe verifies that the prepared disk, evaluation ISO, guest setup ISO,
guest SSH key, and QEMU monitor socket are present. It also records loopback TCP
connectivity to the documented VNC, RDP, WinRM, and SSH forwards. QEMU user-mode
forwarding can accept a host TCP connection even when the Windows guest service
behind it is absent or blocked, so TCP connectability is not treated as guest
readiness.

The `ssh_banner_responsive` field is the protocol-aware readiness check for the
forwarded SSH service. `guest_remote_channel_ready` remains false until the
forwarded service answers with an SSH protocol banner.

The VM also supports a no-network exchange-disk execution path for bootstrap and
evidence capture. The host prepares an MBR-partitioned FAT image:

```text
vm/windows11/exchange_mbr.img
```

The image contains `probe.cmd`, is hot-plugged through the QEMU monitor as a USB
storage device, and is assigned `F:` by the prepared Windows guest. Running
`F:\probe.cmd` from the elevated command prompt writes:

```text
vm/windows11/a11y-win-probe.txt
```

`windows_vm_probe --json` reports this path through
`exchange_probe_done`, `exchange_uia_client_available`, and
`guest_execution_channel_ready`. On 2026-08-14 the prepared VM produced:

```text
drive=F:
Mandatory Label\High Mandatory Level
uia_root_process_id=728
uia_client_available=true
```

OpenSSH Server was not installed in the guest (`sc query sshd` returned service
error 1060), and `Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0`
did not complete during the setup attempt. Therefore the exchange-disk path is
the current proven guest execution channel.

The same exchange-disk path now runs a public UI Automation provider/client
smoke probe inside the prepared guest. The host copies
`vm/windows11/uia_public_provider_probe.txt` as `F:\provider.ps1` and
`vm/windows11/run_uia_public_provider_probe.cmd` as `F:\runprov.cmd`. The probe
creates a raw unmanaged-style provider object through the Windows UI Automation
provider interfaces, returns it from `WM_GETOBJECT`, traverses it through the
public `System.Windows.Automation` client API, reads its properties, requests the
Invoke pattern, invokes it, and writes:

```text
vm/windows11/a11y-uia-public-provider.txt
```

On 2026-08-14 the prepared VM produced:

```text
provider_window_created=true
public_uia_client_found_provider=true
provider_name=A11y VM Public Provider Button
provider_automation_id=a11y.vm.public.provider.button
provider_control_type=ControlType.Button
provider_enabled=true
invoke_pattern_available=true
invoke_count=1
status=success
```

`windows_vm_probe --json` reports this as
`public_uia_provider_result_present`, `public_uia_client_found_provider`, and
`public_uia_provider_invoke_succeeded`. This proves that a public Windows UIA
client can discover and operate an exported provider object inside the VM. It is
still not the final Ada fixture-provider conformance evidence; that next step
requires a Windows-built a11y fixture process exporting the library's semantic
provider through the production UIA backend.

## Qualification Target

The VM is used for public-client testing only. Backend-private inspection does not
count as native UI Automation evidence. The expected qualification path is:

1. Build the Ada fixture and Windows UIA client on Windows.
2. Run the fixture process.
3. Traverse it through the public UI Automation client API.
4. Record normalized observations in the a11y conformance report.

The Windows bridge also exposes a deliberately narrow client-runtime smoke
probe through `native_client_uia --probe-external-client`. On Windows this calls
the public UI Automation client runtime with `CoCreateInstance
(CLSID_CUIAutomation)` and `GetRootElement`; on non-Windows hosts the same
probe reports the guarded stub as unavailable. This proves COM/UIA client
runtime availability and linker/ABI wiring for the test executable, but it is
not by itself provider conformance evidence.

The same command also includes a Windows-only host-window handshake probe. It
creates a hidden test window, sends `WM_GETOBJECT` with `UiaRootObjectId`, and
records whether `UiaReturnRawElementProvider` is reached. The probe passes a
null provider pointer and records
`windows_uia_host_window_null_provider_returned_zero`, so it verifies only that
the host-window UIA message path is callable in the VM.

A second Windows-only smoke probe returns a minimal native
`IRawElementProviderSimple` object from that host-window path. It records
`windows_uia_minimal_provider_*` fields for COM reference counting,
`UiaReturnRawElementProvider`, and `ElementFromHandle`. This proves more of the
native runtime ABI than the null-provider handshake, but the object deliberately
contains no a11y semantic dispatch. Production UIA evidence still requires an
exported a11y fragment root to be returned from that path and traversed by a
public `IUIAutomation` client.

A third Windows-only smoke probe reports `windows_uia_callback_provider_*`.
That provider is still a small native test object, but all
`IRawElementProviderSimple`, `IRawElementProviderFragment`, and
`IRawElementProviderFragmentRoot` vtable methods call back into Ada with stable
session/provider/method identifiers. The full-frame callback also carries the
stable object token plus interface, method, and direction fields, proving the
native COM object identity reaches Ada without depending on pointer addresses.
After the external-client fixture exports its public root, that full-frame
callback is the production `UIA_Native_Callbacks.Dispatch_Interface_Frame_Callback`,
so the Windows VM probe can route native COM vtable calls through the same Ada
object table, provider registry, live export frame decoder, and semantic
provider boundary used by the backend. The provider also uses the production
`UIA_Native_Callbacks.Copy_Property_Value_Callback` path to copy checked
semantic string properties into the native shim for BSTR result marshalling.
The same callback-provider smoke path uses
`UIA_Native_Callbacks.Copy_Runtime_Id_Callback` to copy semantic runtime-id
components into the native shim for `SAFEARRAY(VT_I4)` marshalling from
`IRawElementProviderFragment.GetRuntimeId`.
It is not yet a public UIA conformance claim because public `IUIAutomation`
traversal still has to observe the exported provider from outside the backend.
