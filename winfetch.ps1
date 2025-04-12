# https://github.com/Priyanshu-1012/winfetch
# https://github.com/lptstr/winfetch
# https://www.action1.com/check-missing-windows-updates-script/
# https://guidetux.com.br/neofetch-morto-aqui-7-alternativas-linux/
# https://www.cyberciti.biz/howto/neofetch-awesome-system-info-bash-script-for-linux-unix-macos/

class winfetch {
	static [array] $color = @(
		"$([char]27)[0m",    # reset
		"$([char]27)[0;31m", # darkred
		"$([char]27)[0;34m", # darkblue
		"$([char]27)[0;32m", # darkgreen
		"$([char]27)[1;33m", # darkyellow
		"$([char]27)[1m"     # bold
	)


	static [array] $terminais = @(
		'powershell',
		'pwsh',
		'winpty-agent',
		'cmd',
		'zsh',
		'sh',
		'bash',
		'fish',
		'env',
		'nu',
		'elvish',
		'csh',
		'tcsh',
		'python',
		'xonsh'
	)


	# Logo
	static [array] win2003() {
		return @(
			"",
			"\c1        ,.=:!!t3Z3z.,\c0                    ",
			"\c1       :tt:::tt333EE3\c0                    ",
			"\c1       Et:::ztt33EEEL\c0\c3 @Ee.,      ..,\c0     ",
			"\c1      ;tt:::tt333EE7\c0\c3 ;EEEEEEttttt33#\c0     ",
			"\c1     :Et:::zt333EEQ.\c0\c3 `$EEEEEttttt33QL\c0     ",
			"\c1     it::::tt333EEF\c0\c3 @EEEEEEttttt33F\c0      ",
			"\c1    ;3=*^```````"*4EEV\c0\c3 :EEEEEEttttt33@.\c0      ",
			"\c2    ,.=::::!t=.,\c0 \c1``\c0\c3 @EEEEEEtttz33QF\c0       ",
			"\c2   ;::::::::zt33)\c0\c3   `"4EEEtttji3P*\c0        ",
			"\c2  :t::::::::tt33\c0\c4 :Z3z..  \c0\c3````\c0\c4 ,..g.\c0        ",
			"\c2  i::::::::zt33F\c0\c4 AEEEtttt::::ztF\c0         ",
			"\c2 ;:::::::::t33V\c0\c4 ;EEEttttt::::t3\c0          ",
			"\c2 E::::::::zt33L\c0\c4 @EEEtttt::::z3F\c0          ",
			"\c2{3=*^```````"*4E3)\c0\c4 ;EEEtttt:::::tZ``\c0          ",
			"\c2             ``\c0\c4 :EEEEtttt::::z7",
			"\c4                 `"VEzjt:;;z>*``\c0",
			""
		)
	}




	# Get the main processes of the current powershell instance.
	static [string] getterminal() {
		if (( get-variable psversiontable -valueonly ).psedition.tostring() -ne 'Core' ) {
			$cimsession = new-cimsession
			$parent     = get-process -id ( get-ciminstance -classname win32_process -filter "processid = $( get-variable pid -valueonly )" -property parentprocessid -cimsession $cimsession ).parentprocessid -erroraction ignore

			for () {
				if ( $parent.processname -in [winfetch].terminais ) {
					$parent = get-process -id ( get-ciminstance -classname win32_process -filter "processid = $( $parent.id )" -property parentprocessid -cimsession $cimsession ).parentprocessid -erroraction ignore
					continue
				}
				break
			}
		}

		else {
			$parent = ( get-process -id ( get-variable pid -valueonly )).parent
			for () {
				if ( $parent.processname -in [winfetch].terminais ) {
					$parent = ( get-process -id $parent.id ).parent
					continue
				}
				break
			}
		}

		$terminal = switch ( $parent.processname ) {
			({ $psitem -in 'explorer', 'conhost' }) { 'Windows Console'    }
			( 'Console'                           ) { 'Console2/Z'         }
			( 'ConEmuC64'                         ) { 'ConEmu'             }
			( 'WindowsTerminal'                   ) { 'Windows Terminal'   }
			( 'FluentTerminal.SystemTray'         ) { 'Fluent Terminal'    }
			( 'Code'                              ) { 'Visual Studio Code' }

			default { $psitem }
		}

		if ( -not $terminal ) {
			$terminal = '(Unknown)'
		}

		return $terminal
	}


	static [string] getcpu() {
		$reg = [microsoft.win32.registrykey]::openremotebasekey( 'localmachine', $env:computername )
		$cpu = $reg.opensubkey( 'hardware\description\system\centralprocessor\0' )
		$cpuname = $cpu.getvalue( "processornamestring" )
		$cpuname = if ( $cpuname.contains( '@' )) {
			( $cpuname -split '@' )[0].Trim()
		} else {
			$cpuname.Trim()
		}

		# [math]::Round($cpu.GetValue("~MHz") / 1000, 1) is 2-5ms slower
		return "$cpuname @ $( $cpu.getvalue( '~MHz' ) / 1000 )GHz"
	}


	# https://stackoverflow.com/a/77909075
	static [array] getip() {
		try {
			$public = ( invoke-webrequest 'ifconfig.me/ip' ).content
		}
		catch {
			$public = '0.0.0.0'
		}

		$private = ( -split ( ipconfig | where { $psitem -match 'ipv4' } ))
		if ( $private.length -gt 0 ) {
			$private = $private[-1]
		}
		else {
			$private = '0.0.0.0'
		}

		return @(
			$private,
			$public
		)
	}


	static [array] wingetupgrade() {
		$apps  = @()
		$start = $false

		# Remove unnecessary first lines
		winget upgrade --accept-source-agreements --include-unknown | foreach-object {
			if ( $psitem -match '^([-]+)$' ) {
				$start = $true
			}
			elseif ( $start -eq $true ) {
				$apps += $psitem
			}
		}

		# Remove the last line
		$apps = $apps[ 0..( $apps.length - 2 ) ]

		return $apps
	}


	static [array] scoopupgrade() {
		$result = ( invoke-expression 'powershell -command scoop status' ).trim()  -match '\S'
		$start  = $false
		$apps   = @()

		if ( $result -match "Run 'scoop update'" ) {
			$apps += 'scoop'
		}

		$result | foreach-object {
			if ( $psitem -match '^([-\s]+)$' ) {
				$start = $true
			}
			elseif ( $start -eq $true ) {
				$apps += $psitem
			}
		}

		return $apps
	}
}




function winfetch() {
param(
	# Use this parameter to exclude some results
	[parameter( mandatory = $false )]
	[string] $exclude
)


	[int] $curline = 2

	# logo
	$lines = [winfetch]::win2003()


	# User, computer name and separetor
	$logged    = [environment]::username + '@' + $( hostname )
	$lines[1] += $logged
	$lines[2] += $( '-' * $logged.length )

	# OS
	$curline++
	$version = get-itemproperty 'hklm:\software\microsoft\windows nt\currentversion'
	$lines[ $curline ] += "\c5OS\c0: $( $version.productname ) $( $version.displayversion ) [" + $( switch( [intptr]::size ) {
		({ $psitem -eq 8 }) { 'x64 bits' }
		({ $psitem -eq 4 }) { 'x86 bits' }
	}) + ']'

	# Host. Computer info
	$curline++
	$bios = get-itemproperty 'hklm:\hardware\description\system\bios'
	$lines[ $curline ] += "\c5Host\c0: $( $bios.biosvendor ) $( $bios.systemfamily )"

	# Kernel
	$curline++
	$lines[ $curline ] += "\c5Kernel\c0: $( [environment]::osversion.version.tostring() )"

	# MotherBoard
	$curline++
	$lines[ $curline ] += "\c5MotherBoard\c0: $( $bios.baseboardmanufacturer ) $( $bios.baseboardproduct )"

	# Uptime
	$curline++
	$lines[ $curline ] += '\c5Uptime\c0: ' + $( switch( get-uptime ) {
		({ $psitem.days    -eq 1 }) { '1 day' }
		({ $psitem.days    -gt 1 }) { "$( $psitem.days ) days" }
		({ $psitem.hours   -eq 1 }) { '1 hour' }
		({ $psitem.hours   -gt 1 }) { "$( $psitem.hours ) hours" }
		({ $psitem.minutes -eq 1 }) { '1 minute' }
		({ $psitem.minutes -gt 1 }) { "$( $psitem.minutes ) minutes" }
	}) -join ' '


	if ( $exclude -notmatch 'packages' ) {
		$curline++
		$lines[ $curline ] += '\c5Packages\c0: '

		# https://www.saashub.com/best-package-manager-software
		if ( $exclude -notmatch 'winget' ) {
			$winget = [winfetch]::wingetupgrade().length

			# Check Updates in winget
			if ( $winget -gt 0 ) {
				$lines[ $curline ] += "$winget (winget), "
			}
		}

		# Se tiver scoop instalado, verifica atualizações
		if ( $exclude -notmatch 'scoop' ) {
			if ( [bool]( get-command -name scoop -erroraction silentlycontinue )) {
				$apps = [winfetch]::scoopupgrade()
				if ( $apps.length -gt 0 ) {
					$lines[ $curline ] += "$( $apps.length ) (scoop), "
				}
			}
		}

		$lines[ $curline ] = $lines[ $curline ] -replace ', $', ''
	}



	if ( $exclude -notmatch 'shell' ) {
		$curline++
		$lines[ $curline ]  += "\c5Shell\c0: Powershell v$( $psversiontable.psversion )"
	}


	$curline++
	$lines[ $curline ] += "\c5Resolution\c0: "
	add-type -assemblyname system.windows.forms
	[windows.forms.screen]::allscreens | foreach-object {
		$name = ( $psitem.devicename -replace '.*\\([\w]+)$', '$1' ).tolower()
		$lines[ $curline ] += "$( $psitem.bounds.width )x$( $psitem.bounds.height ) ($name), "
	}
	$lines[ $curline ] = $lines[ $curline ] -replace ', $', ''


	$curline++
	$lines[ $curline ]  += "\c5Terminal\c0: $( [winfetch]::getterminal() )"


	$curline++
	$winsat = get-itemproperty 'hklm:\software\microsoft\windows nt\currentversion\winsat'
	$lines[ $curline ] += "\c5GPU\c0: $( $winsat.primaryadapterstring )"
	# ( get-wmiobject win32_videocontroller ).videoprocessor[1]


	$curline++
	$lines[ $curline ]  += "\c5CPU\c0: $( [winfetch]::getcpu() )"
	# ( get-ciminstance -classname win32_processor ).name


	if ( $exclude -notmatch 'ip\b' ) {
		$curline++
		$ips = [winfetch]::getip()
		$lines[ $curline ] += "\c5IPs\c0: $( $ips[0] ) (Private)"

		if ( $exclude -notmatch 'ippub' ) {
			$lines[ $curline ]  += ", $( $ips[1] ) (Public)"
		}
	}

	for ( $index = 0; $index -lt [winfetch]::color.length; $index++ ) {
		$lines = $lines -replace "\\c$index", [winfetch]::color[ $index ]
	}

	for ( $index = 0; $index -lt $lines.length; $index++ ) {
		write-host $lines[ $index ]
	}
}
