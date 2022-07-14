#Requires -Modules Pscx
#Requires -Version 5.0

BeforeAll {
	$NewNuspecScriptPath = "${PSScriptRoot}\..\src\New-Nuspec.ps1"
	function New-Nuspec { . $NewNuspecScriptPath @args }
}

Describe 'has expected parameters' -ForEach @(
	@{Parameter = 'ManifestPath'; Type = [string]; Mandatory = $true }
	@{Parameter = 'DestinationFolder'; Type = [string]; Mandatory = $false }
) {
	It 'has expected parameters' {
		Get-Command $NewNuspecScriptPath | Should -HaveParameter $parameter -Mandatory:$mandatory 
	}
}

Describe 'Create nuspec from an existing file' {
	BeforeAll {
		$ManifestPath = 'TestDrive:\foo.psd1'
		$NuspecPath = 'TestDrive:\'
		$NuspecFile = "${NuspecPath}\foo.nuspec"
		$SchemaPath = "${PSScriptRoot}\..\resources\nuspec.xsd"

		New-ModuleManifest -Path $ManifestPath
		New-Nuspec `
			-ManifestPath $ManifestPath `
			-DestinationFolder $NuspecPath `
			-ErrorAction Ignore
	}
	It 'Check nuspec file' {
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

Describe 'Default localtion for NuSpec' -ForEach @(
	@{ManifestPath = 'TestDrive:\foo.psd1'; NuspecFile = 'TestDrive:\foo.nuspec' }
	@{ManifestPath = 'TestDrive:\bar.psd1'; NuspecFile = 'TestDrive:\bar.nuspec' }
	@{ManifestPath = 'TestDrive:\foo-bar.psd1'; NuspecFile = 'TestDrive:\foo-bar.nuspec' }
	@{ManifestPath = 'TestDrive:\foo_bar.psd1'; NuspecFile = 'TestDrive:\foo_bar.nuspec' }
) {
	BeforeAll {
		New-ModuleManifest -Path $ManifestPath
		New-Nuspec -ManifestPath $ManifestPath -ErrorAction Ignore
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
	It "Thows if the manifest doesn't exist" {
		$ManifestPath = 'TestDrive:\non-existing-manifest.psd1'
		{ New-Nuspec -ManifestPath $ManifestPath } | Should -Throw 
	}

	Describe 'Throws for non *.psd1 file' {
		BeforeAll {
			$ManifestPath = 'TestDrive:\non-existing-manifest.txt'
			New-Item -Path $ManifestPath -ItemType File
		} 
		
		It 'Throws for non valid manifest file' {
			{ New-Nuspec -ManifestPath $ManifestPath -ErrorAction Ignore } | Should -Throw 
		}

		AfterAll {
			Remove-Item `
				-Path $ManifestPath `
				-Recurse `
				-Force `
				-ErrorAction Ignore
		}
	}

	Describe 'Throws for invalid *.psd1 file' {
		BeforeAll {
			$ManifestPath = 'TestDrive:\foo.psd1'
			New-Item -Path $ManifestPath -ItemType File
		} 
		
		It 'Throws for non valid manifest file' {
			{ New-Nuspec -ManifestPath $ManifestPath -ErrorAction Ignore } | Should -Throw 
		}

		AfterAll {
			Remove-Item `
				-Path $ManifestPath `
				-Recurse `
				-Force `
				-ErrorAction Ignore
		}
	}

	Describe "Thows if destination folder doesn't exist" {
		BeforeAll {
			$ManifestPath = 'TestDrive:\foo.psd1'
			New-ModuleManifest -Path $ManifestPath
		}
		It "Thows if destination folder doesn't exist" {
			{ New-Nuspec -ManifestPath $ManifestPath -DestinationFolder 'TestDrive:\non-existing-folder' } | Should -Throw 
		}

		AfterAll {
			Remove-Item `
				-Path $ManifestPath `
				-Force `
				-Recurse `
				-ErrorAction Ignore
		}
	}
}

Describe 'Generated nuspec contains the right data' {
	Describe 'Default values' {
		BeforeAll {
			$FileName = 'foo'
			$ManifestPath = "TestDrive:\${FileName}.psd1"
			$NuspecPath = "TestDrive:\${FileName}.nuspec"
			
			New-ModuleManifest -Path $ManifestPath -Author $Author
			
			New-Nuspec -ManifestPath $ManifestPath -ErrorAction Ignore
			[xml]$nuspecXml = Get-Content -Path $NuspecPath
		}
		
		It 'Check Id' {
			$nuspecXml.package.metadata.Id | Should -Be $FileName
		}

		It '<property> should be <value>' -TestCases @(
			@{ Property = 'Id'; Value = $FileName }
			@{ Property = 'Version'; Value = '0.0.1' }
			@{ Property = 'authors'; Value = $env:USERNAME }
			@{ Property = 'owners'; Value = 'Unknown' }
			@{ Property = 'description'; Value = '' }
			@{ Property = 'releaseNotes'; Value = '' }
			@{ Property = 'requireLicenseAcceptance'; Value = 'false' }
			@{ Property = 'copyright'; Value = "(c) ${env:USERNAME}. All rights reserved." }
			@{ Property = 'tags'; Value = 'PSModule' }
			@{ Property = 'title'; Value = $null }
			@{ Property = 'licenseUrl'; Value = $null }
			@{ Property = 'projectUrl'; Value = $null }
			@{ Property = 'iconUrl'; Value = $null }
			@{ Property = 'developmentDependency'; Value = $null }
			@{ Property = 'summary'; Value = $null }
			@{ Property = 'language'; Value = $null }
			@{ Property = 'serviceable'; Value = $null }
			@{ Property = 'icon'; Value = $null }
			@{ Property = 'readme'; Value = $null }
			@{ Property = 'repository'; Value = $null }
			@{ Property = 'repository'; Value = $null }
			@{ Property = 'license'; Value = $null }
			@{ Property = 'packageTypes'; Value = $null }
			@{ Property = 'frameworkAssemblies'; Value = $null }
			@{ Property = 'frameworkReferences'; Value = $null }
			@{ Property = 'references'; Value = $null }
			@{ Property = 'contentFiles'; Value = $null }
		) {
			$nuspecXml.package.metadata.$property | Should -Be $value
		}

		AfterAll {
			Remove-Item `
				-Path $ManifestPath, $NuspecPath `
				-Recurse `
				-Force `
				-ErrorAction Ignore
		}
	}

	Describe 'Generated nuspec contains the specified author' {
		BeforeAll {
			$ManifestPath = 'TestDrive:\foo.psd1'
			$NuspecPath = 'TestDrive:\foo.nuspec'
			$Author = 'bus1hero'
			New-ModuleManifest -Path $ManifestPath -Author $Author
				
			New-Nuspec -ManifestPath $ManifestPath -ErrorAction Ignore
			[xml]$nuspecXml = Get-Content -Path $NuspecPath
		}

		It 'Generated Nuspec contains expected author' {
			$nuspecXml.package.metadata.authors | Should -Be $Author
		}
			
		AfterAll {
			Remove-Item `
				-Path $ManifestPath, $NuspecPath `
				-Recurse `
				-Force `
				-ErrorAction Ignore
		}
	}
}