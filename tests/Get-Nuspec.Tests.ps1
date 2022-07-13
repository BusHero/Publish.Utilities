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
		It 'Id' {
			$nuspecXml.package.metadata.id | Should -Be $FileName
		}
		It 'Version' {
			$nuspecXml.package.metadata.version | Should -Be '0.0.1'
		}
		It 'Authors' {
			$nuspecXml.package.metadata.authors | Should -Be $env:USERNAME
		}
		It 'Owners' {
			$nuspecXml.package.metadata.owners | Should -Be 'Unknown'
		}
		It 'Description' {
			$nuspecXml.package.metadata.description | Should -Be '' 
		}
		It 'releaseNotes' {
			$nuspecXml.package.metadata.releaseNotes | Should -Be ''
		}
		It 'requireLicenseAcceptance' {
			$nuspecXml.package.metadata.requireLicenseAcceptance | Should -Be 'false'
		}
		It 'copyright' {
			$nuspecXml.package.metadata.copyright | Should -Be "(c) ${env:USERNAME}. All rights reserved."
		}
		It 'tags' {
			$nuspecXml.package.metadata.tags | Should -Be 'PSModule'
		}
		It 'title' {
			$nuspecXml.package.metadata.title | Should -Be $null
		}
		It 'licenseUrl' {
			$nuspecXml.package.metadata.licenseUrl | Should -Be $null
		}
		It 'projectUrl' {
			$nuspecXml.package.metadata.projectUrl | Should -Be $null
		}
		It 'iconUrl' {
			$nuspecXml.package.metadata.iconUrl | Should -Be $null
		}
		It 'developmentDependency' {
			$nuspecXml.package.metadata.developmentDependency | Should -Be $null
		}
		It 'summary' {
			$nuspecXml.package.metadata.summary | Should -Be $null
		}
		It 'language' {
			$nuspecXml.package.metadata.language | Should -Be $null
		}
		It 'serviceable' {
			$nuspecXml.package.metadata.serviceable | Should -Be $null
		}
		It 'icon' {
			$nuspecXml.package.metadata.icon | Should -Be $null
		}
		It 'readme' {
			$nuspecXml.package.metadata.readme | Should -Be $null
		}
		It 'repository' {
			$nuspecXml.package.metadata.repository | Should -Be $null
		}
		It 'repository' {
			$nuspecXml.package.metadata.repository | Should -Be $null
		}
		It 'license' {
			$nuspecXml.package.metadata.license | Should -Be $null
		}
		It 'packageTypes' {
			$nuspecXml.package.metadata.packageTypes | Should -Be $null
		}
		It 'frameworkAssemblies' {
			$nuspecXml.package.metadata.frameworkAssemblies | Should -Be $null
		}
		It 'frameworkReferences' {
			$nuspecXml.package.metadata.frameworkReferences | Should -Be $null
		}
		It 'references' {
			$nuspecXml.package.metadata.references | Should -Be $null
		}
		It 'contentFiles' {
			$nuspecXml.package.metadata.contentFiles | Should -Be $null
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