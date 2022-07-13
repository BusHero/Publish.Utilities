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
	BeforeAll {
		$ManifestPath = 'TestDrive:\foo.psd1'
		$NuspecPath = 'TestDrive:\'
		$NuspecFile = "${NuspecPath}\foo.nuspec"
		$SchemaPath = "${PSScriptRoot}\..\resources\nuspec.xsd"

		New-ModuleManifest -Path $ManifestPath
		fnStateChangingDemo -ManifestPath $ManifestPath -DestinationFolder $NuspecPath
	}
	It 'Check nuspec file' {
		Test-Xml -Path $NuspecFile -SchemaPath $SchemaPath | Should -BeTrue
	}
}

Describe 'Default localtion for NuSpec' {
	BeforeAll {
		$ManifestPath = 'TestDrive:\foo.psd1'
		$NuspecFile = 'TestDrive:\foo.nuspec'
	
		New-ModuleManifest -Path $ManifestPath
		fnStateChangingDemo -ManifestPath $ManifestPath
	}

	It 'File was created' {
		$NuspecFile | Should -Exist
	}

	It 'Generated file should comply with nuspec schema' {
		Test-Xml -Path $NuspecFile -SchemaPath $SchemaPath | Should -BeTrue
	}

	AfterAll {
		Remove-Item `
			-Path $ManifestPath, $NuspecFile `
			-Recurse `
			-Force `
			-ErrorAction Ignore
	}
}