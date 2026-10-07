# 
# Copyright (c) 2026 ETH Zürich, IT Services
# 
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
# 

[CmdletBinding()]
param
(
	[Parameter(Mandatory = $true)]
	[string] $Directory
)

$ErrorActionPreference = 'Stop'

try
{
	$signtool = Get-Command -Name 'signtool.exe' -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1

	if (-not (Test-Path -LiteralPath $Directory -PathType Container))
	{
		throw "Could not find directory '$Directory'!"
	}

	$root = (Resolve-Path -LiteralPath $Directory).ProviderPath.TrimEnd('\')
	$binaries = @(Get-ChildItem -LiteralPath $root -Recurse -File | Where-Object { $_.Extension -eq '.exe' -or $_.Extension -eq '.dll' })

	if ($binaries.Count -eq 0)
	{
		throw "Could not find any binaries to sign in directory '$root'!"
	}

	$thumbprint = 'ecac9df025f5d208f6190fc4d6f9d329576598c7'
	$cert = Get-Item "Cert:\CurrentUser\My\$thumbprint", "Cert:\LocalMachine\My\$thumbprint" -ErrorAction SilentlyContinue | Select-Object -First 1

	if (-not $cert -or $env:SKIP_CODE_SIGNING -eq 'true')
	{
		Write-Warning "Code signing certificate '$thumbprint' was not found or SKIP_CODE_SIGNING is set. Skipping binary signing in '$root'."
		exit 0
	}

	if (-not $signtool)
	{
		throw 'Could not find SignTool (signtool.exe)!'
	}

	$paths = @($binaries | ForEach-Object { $_.FullName.Substring("$root\".Length) })
	$previous = [System.Environment]::CurrentDirectory

	try
	{
		$timestampServer = 'http://timestamp.digicert.com'

		Push-Location -LiteralPath $root
		[System.Environment]::CurrentDirectory = $root

		Write-Host "Attempting to sign $($binaries.Count) binaries in '$root'..."

		& $signtool sign /sha1 $thumbprint /sm /tr $timestampServer /td sha256 /fd sha256 $paths

		if ($LASTEXITCODE -ne 0)
		{
			throw "SignTool failed with exit code ${LASTEXITCODE}!"
		}
	}
	finally
	{
		[System.Environment]::CurrentDirectory = $previous
		Pop-Location
	}

	Write-Host "Successfully signed all $($paths.Count) binaries."

	exit 0
}
catch
{
	Write-Host "Signing the binaries in '$Directory' has failed! Reason: $($_.Exception.Message)"

	exit 1
}
