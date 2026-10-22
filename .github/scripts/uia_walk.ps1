# Walks the UI Automation tree a11ykit exposes, the way Narrator would reach
# it: from the provider's window, through UIAutomationClient.
param([int]$Seconds = 20)
Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class Win {
  [DllImport("user32.dll", CharSet = CharSet.Unicode)]
  public static extern IntPtr FindWindow(string cls, string title);
}
"@
$deadline = (Get-Date).AddSeconds($Seconds)
$hwnd = [IntPtr]::Zero
while ($hwnd -eq [IntPtr]::Zero -and (Get-Date) -lt $deadline) {
  Start-Sleep -Milliseconds 250
  $hwnd = [Win]::FindWindow($null, "A11yKit UIA Provider")
}
if ($hwnd -eq [IntPtr]::Zero) { Write-Output "no provider window"; exit 2 }
Write-Output "provider window $hwnd"
$walker = [System.Windows.Automation.TreeWalker]::RawViewWalker
$count = 0
function Walk($element, $depth) {
  $script:count++
  $c = $element.Current
  Write-Output ("{0}{1} [{2}] focused={3}" -f ("  " * $depth), $c.Name, $c.ControlType.ProgrammaticName, $c.HasKeyboardFocus)
  if ($depth -gt 6) { return }
  $child = $walker.GetFirstChild($element)
  while ($child -ne $null) {
    Walk $child ($depth + 1)
    $child = $walker.GetNextSibling($child)
  }
}
$root = [System.Windows.Automation.AutomationElement]::FromHandle($hwnd)
Walk $root 0
Write-Output "elements $count"
$names = @()
$all = $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)
foreach ($e in $all) { $names += $e.Current.Name }
if ($names -contains "first.txt") { Write-Output "found first.txt"; exit 0 }
Write-Output "first.txt not reachable"; exit 1
