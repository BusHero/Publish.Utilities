#Requires -Modules Pscx
#Requires -Version 5.0

BeforeAll {
	$GetNuspecScriptPath = "${PSScriptRoot}\..\src\Get-Nuspec.ps1"
	function Get-Nuspec { . $GetNuspecScriptPath @args }
}

Describe 'has expected parameters' -ForEach @(
	@{Parameter = 'ManifestPath'; Type = [string]; Mandatory = $true }
	@{Parameter = 'DestinationFolder'; Type = [string]; Mandatory = $false }
) {
	It 'has expected parameters' {
		Get-Command $GetNuspecScriptPath | Should -HaveParameter $parameter -Mandatory:$mandatory 
	}
}

Describe 'Create nuspec from an existing file' {
	BeforeAll {
		$ManifestPath = 'TestDrive:\foo.psd1'
		$NuspecPath = 'TestDrive:\'
		$NuspecFile = "${NuspecPath}\foo.nuspec"
		$SchemaPath = "${PSScriptRoot}\..\resources\nuspec.xsd"

		New-ModuleManifest -Path $ManifestPath
		Get-Nuspec -ManifestPath $ManifestPath -DestinationFolder $NuspecPath
	}
	It 'Check nuspec file' {
		Test-Xml -Path $NuspecFile -SchemaPath $SchemaPath | Should -BeTrue
	}
}

Describe 'Default localtion for NuSpec' -ForEach @(
	@{ManifestPath = 'TestDrive:\foo.psd1'; NuspecFile = 'TestDrive:\foo.nuspec' }
	@{ManifestPath = 'TestDrive:\bar.psd1'; NuspecFile = 'TestDrive:\bar.nuspec' }
	@{ManifestPath = 'TestDrive:\foo-bar.psd1'; NuspecFile = 'TestDrive:\foo-bar.nuspec' }
	@{ManifestPath = 'TestDrive:\foo_bar.psd1'; NuspecFile = 'TestDrive:\foo_bar.nuspec' }
) {
	BeforeAll {
		New-ModuleManifest -Path $ManifestPath
		Get-Nuspec -ManifestPath $ManifestPath
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

Describe 'Invalid manifest' {
	It "Thows if the the manifest doesn't exist" {
		$ManifestPath = 'TestDrive:/non-existing-manifest.psd1'
		# . $GetNuspecScriptPath -ManifestPath $ManifestPath
	}
}