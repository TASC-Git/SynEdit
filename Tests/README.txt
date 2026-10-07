Upstream integration regression tests

Run with Delphi 13.2 and its bundled DUnit sources:

  powershell -NoProfile -ExecutionPolicy Bypass -File Tests\run-tests.ps1

Use -BdsRoot to select another Delphi installation. By default the script
builds and runs both Win32 and Win64, writing generated files to Tests\Output.

The tests cover ANSI export round trips and binary-mode state/notifications
when hooking and unhooking external or shared editor buffers. The tests do
not change the system clipboard or install packages into the IDE.

SQL Delta's TestVirtualSynEditEdit suite is maintained in the consumer
repository and should also be run against this integration branch.
