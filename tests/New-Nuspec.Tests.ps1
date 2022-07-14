#Requires -Modules Pscx, Pester
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

	Describe 'Tags are generated correctly' -ForEach @(
		@{ Params = @{ Tags = 'foo', 'bar' }; Tags = 'foo', 'bar', 'PSModule' }
		@{ Params = @{ Tags = 'foo', 'foo' }; Tags = 'foo', 'PSModule' }
	) {
		BeforeAll {
			$ManifestPath = 'TestDrive:\foo.psd1'
			$NuspecPath = 'TestDrive:\foo.nuspec'

			New-ModuleManifest -Path $ManifestPath @params
			New-Nuspec -ManifestPath $ManifestPath -ErrorAction Ignore

			[xml]$nuspecXml = Get-Content -Path $NuspecPath
		}
		
		It 'Generated nuspec file contains "<tags>" tags' {
			$nuspecXml.package.metadata.tags -split ' ' | Sort-Object | Should -Be @($tags | Sort-Object)
		}

		AfterAll {
			Remove-Item `
				-Path $ManifestPath, $NuspecPath `
				-Recurse `
				-Force `
				-ErrorAction Ignore
		}
	}

	Describe 'license' {
		Describe 'Valid license' {
			Describe 'Empty license file' {
				# TODO make the test case to fail
				BeforeAll {
					$FileName = 'foo'
					$ManifestPath = "TestDrive:\${FileName}.psd1"
					$NuspecPath = "TestDrive:\${FileName}.nuspec"
					$LicenseFile = "$TestDrive/license.txt"
					$LicenseUri = "file:///${LicenseFile}".Replace('\', '/')
	
					New-Item -Path $LicenseFile -ItemType File
					New-ModuleManifest -Path $ManifestPath -LicenseUri $LicenseUri
					New-Nuspec -ManifestPath $ManifestPath -ErrorAction Ignore
					[xml]$nuspecXml = Get-Content -Path $NuspecPath
				}

				It 'license property is <licenseUri>' {
					$nuspecXml.package.metadata.licenseUrl | Should -Be $LicenseUri
				}
			
				It 'RequireLicenseAcceptance is false' {
					$nuspecXml.package.metadata.RequireLicenseAcceptance | Should -Be 'false'
				}

				AfterAll {
					Remove-Item `
						-Path $ManifestPath, $LicenseFile, $NuspecPath `
						-Recurse `
						-Force `
						-ErrorAction Ignore
				}
			}

			Describe 'Non existing license file' {
				# TODO make the test case to fail
				BeforeAll {
					$FileName = 'foo'
					$ManifestPath = "TestDrive:\${FileName}.psd1"
					$NuspecPath = "TestDrive:\${FileName}.nuspec"
					$LicenseFile = "$TestDrive/license.txt"
					$LicenseUri = "file:///${LicenseFile}".Replace('\', '/')
	
					New-ModuleManifest -Path $ManifestPath -LicenseUri $LicenseUri
					New-Nuspec -ManifestPath $ManifestPath -ErrorAction Ignore
					[xml]$nuspecXml = Get-Content -Path $NuspecPath
				}

				It 'license property is <licenseUri>' {
					$nuspecXml.package.metadata.licenseUrl | Should -Be $LicenseUri
				}
			
				It 'RequireLicenseAcceptance is false' {
					$nuspecXml.package.metadata.RequireLicenseAcceptance | Should -Be 'false'
				}

				AfterAll {
					Remove-Item `
						-Path $ManifestPath, $NuspecPath `
						-Recurse `
						-Force `
						-ErrorAction Ignore
				}
			}

			Describe 'Non empty license file' {
				BeforeAll {
					$FileName = 'foo'
					$ManifestPath = "TestDrive:\${FileName}.psd1"
					$NuspecPath = "TestDrive:\${FileName}.nuspec"
					$LicenseFile = "$TestDrive/license.txt"
					$LicenseUri = "file:///${LicenseFile}".Replace('\', '/')
					
					Out-File -FilePath $LicenseFile -Encoding utf8 -InputObject 'Some license here and there'
					New-ModuleManifest -Path $ManifestPath -LicenseUri $LicenseUri -RequireLicenseAcceptance
					New-Nuspec -ManifestPath $ManifestPath -ErrorAction Ignore
					[xml]$nuspecXml = Get-Content -Path $NuspecPath
				}
				
				It 'license property is <licenseUri>' {
					$nuspecXml.package.metadata.licenseUrl | Should -Be $LicenseUri
				}
			
				It 'RequireLicenseAcceptance is true' {
					$nuspecXml.package.metadata.RequireLicenseAcceptance | Should -Be 'true'
				}

				AfterAll {
					Remove-Item `
						-Path $ManifestPath, $LicenseFile `
						-Recurse `
						-Force `
						-ErrorAction Ignore
				}
			}
		}

		Describe 'Invalid license' -ForEach @(
			@{Params = @{ LicenseUri = 'https://example.com'; RequireLicenseAcceptance = $true } }
			@{Params = @{ RequireLicenseAcceptance = $true } }
			@{Params = @{ LicenseUri = 'file:///TestDrive:non-existing-license-file.txt'; RequireLicenseAcceptance = $true } }
		) {
			BeforeAll {
				$ManifestPath = 'TestDrive:\foo.psd1'
				New-ModuleManifest `
					-Path $ManifestPath `
					@params
			}
			
			It 'Throw for non valid license file' {
				{ New-Nuspec `
						-ManifestPath $ManifestPath `
						-ErrorAction Ignore } | Should -Throw
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

	Describe 'Generated nuspec contains the specified author' -ForEach @(
		@{ Property = @{ Author = 'bus1hero' }; NuspecProperty = 'authors'; ExpectedValue = 'bus1hero' }
		@{ Property = @{ ModuleVersion = '1.0.0' }; NuspecProperty = 'Version'; ExpectedValue = '1.0.0' }
		# @{ Property = @{ owners = 'owners' }; NuspecProperty = 'owners' }
		@{ Property = @{ description = 'Some description here and there' }; NuspecProperty = 'description'; ExpectedValue = 'Some description here and there' }
		# @{ Property = @{ releaseNotes = 'releaseNotes' }; NuspecProperty = 'releaseNotes' }
		# @{ Property = @{ LicenseUri = 'https://example.com/'; requireLicenseAcceptance = $false }; NuspecProperty = 'requireLicenseAcceptance'; ExpectedValue = 'false' }
		# @{ Property = @{ LicenseUri = 'https://example.com/'; requireLicenseAcceptance = $true }; NuspecProperty = 'requireLicenseAcceptance'; ExpectedValue = 'true' }
		@{ Property = @{ copyright = 'copyright' }; NuspecProperty = 'copyright'; ExpectedValue = 'copyright' }
		# @{ Property = @{ title = 'title' }; NuspecProperty = 'title' }
		@{ Property = @{ LicenseUri = 'https://example.com/' }; NuspecProperty = 'licenseUrl'; ExpectedValue = 'https://example.com/' }
		@{ Property = @{ projectUri = 'https://example.com/' }; NuspecProperty = 'projectUrl'; ExpectedValue = 'https://example.com/' }
		@{ Property = @{ iconUri = 'https://example.com/' }; NuspecProperty = 'https://example.com/' }
		# @{ Property = @{ developmentDependency = 'developmentDependency' }; NuspecProperty = 'developmentDependency' }
		# @{ Property = @{ summary = 'summary' }; NuspecProperty = 'summary' }
		# @{ Property = @{ language = 'language' }; NuspecProperty = 'language' }
		# @{ Property = @{ serviceable = 'serviceable' }; NuspecProperty = 'serviceable' }
		# @{ Property = @{ icon = 'icon' }; NuspecProperty = 'icon' }
		# @{ Property = @{ readme = 'readme' }; NuspecProperty = 'readme' }
		# @{ Property = @{ repository = 'repository' }; NuspecProperty = 'repository' }
		# @{ Property = @{ repository = 'repository' }; NuspecProperty = 'repository' }
		# @{ Property = @{ license = 'license' }; NuspecProperty = 'license' }
		# @{ Property = @{ packageTypes = 'packageTypes' }; NuspecProperty = 'packageTypes' }
		# @{ Property = @{ frameworkAssemblies = 'frameworkAssemblies' }; NuspecProperty = 'frameworkAssemblies' }
		# @{ Property = @{ frameworkReferences = 'frameworkReferences' }; NuspecProperty = 'frameworkReferences' }
		# @{ Property = @{ references = 'references' }; NuspecProperty = 'references' }
		# @{ Property = @{ contentFiles = 'contentFiles' }; NuspecProperty = 'contentFiles' }
	) {
		BeforeAll {
			$ManifestPath = 'TestDrive:\foo.psd1'
			$NuspecPath = 'TestDrive:\foo.nuspec'
			New-ModuleManifest -Path $ManifestPath @property
				
			New-Nuspec -ManifestPath $ManifestPath -ErrorAction Ignore
			[xml]$nuspecXml = Get-Content -Path $NuspecPath
		}

		It 'Generated Nuspec contains expected <NuspecProperty>' {
			$nuspecXml.package.metadata.$NuspecProperty | Should -Be $expectedValue
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