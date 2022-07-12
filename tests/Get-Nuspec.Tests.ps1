#Requires -Modules Pscx
#Requires -Version 5.0

BeforeAll {
	Set-Item function:fnStateChangingDemo ([ScriptBlock]::Create((Get-Content -Raw "${PSScriptRoot}\..\src\Get-Nuspec.ps1")))
}

Describe 'has expected parameters' -ForEach @(
	@{Parameter = 'ManifestPath'; Type = [string]; Mandatory = $true }
	@{Parameter = 'DestinationFolder'; Type = [string]; Mandatory = $false }
) {
	It 'has expected parameters' {
		if ($mandatory) {
			Get-Command fnStateChangingDemo | Should -HaveParameter $parameter -Type $type -Mandatory
		}
		else {
			Get-Command fnStateChangingDemo | Should -HaveParameter $parameter -Type $type
		}
	}
}

Describe 'Create nuspec from an existing file' {
	It ''
}