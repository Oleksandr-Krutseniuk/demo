
$enabledUsers = Get-LocalUser | Where-Object { $_.Enabled -eq $true }

Write-Host ("`n`n{0,-20} {1}" -f "Username", "New_Message_Duration") # ""`n`n{0,-20} {1}"" - форматує вивід.перший стовпчик - 20 символів,2ий-стратує з 21шого
Write-Host "-----------------------------------------"
$newMessageDuration = 91 # строк в секундах

foreach ($user in $enabledUsers) {
    # шлях до гілки з профілями користувачів + директорія з профілем відповідного користувача
    $profileListPath = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$($user.SID.Value)"
    $registryPath = "Registry::HKEY_USERS\$($user.SID.Value)\Control Panel\Accessibility" # в цьому розділі реєєстру знаходиться ключ "MessageDuration"
    
    if (-not (Test-Path $profileListPath)) { # сценарій для обробки користувачів без профіля (створені, але ні разу не логінились)
        Write-Host ("Probably, user '{0}' has not logged on to the server yet. First login needed before 'MessageDuration' value could be changed" -f $user.Name)
        continue
    }
    elseif (Test-Path $registryPath) { # якщо користувач підключений - він є в реєстрі, тому можна зразу редагувати значення
        Set-ItemProperty -Path $registryPath -Name "MessageDuration" -Value $newMessageDuration
        Write-Host ("{0,-20} {1}" -f $user.Name, $newMessageDuration)
    }
    else { # якщо користувач зареєстрований на сервері, вже має профіль, але в офлайні - підвантажую його в реєєстр і в реєстрі змінюю значення
        $userProfilePath = Get-ItemPropertyValue -Path $profileListPath -Name "ProfileImagePath"  # домашня папка користувача (напр. C:\Users\<USERNAME>)
        $ntuserDatPath = Join-Path -Path $userProfilePath -ChildPath "NTUSER.DAT"  # файл профілю користувача(userProfilePath+NTUSER.DAT - напр. C:\Users\<USERNAME>\USER.DAT)
        try {               
            $null = reg load "HKU\$($user.SID.Value)" $ntuserDatPath # загрузка NTUSER.DAT в гілку реєєстра, назва якої відповідає SIDу користувача.
            Set-ItemProperty -Path $registryPath -Name "MessageDuration" -Value $newMessageDuration # зміна MessageDuration в реєстрі
            Write-Host ("{0,-20} {1}" -f $user.Name, $newMessageDuration)
        }
        finally {
            $retryCount = 0
            while ($true) { 
                try {                                                                                                                 
                    $null = reg unload "HKU\$($user.SID.Value)" # вивантаження "офлайн" - користувача з реєстру.
                    break                                                                                                    
                }
                catch { # якщо в "try" помилка - робиться 3 спроби вивантаження (саме тому ці блоки в "while").на 3 спробі цикл вимикається  
                    if ($retryCount -ge 3) {
                        Write-Host "Failed to unload registry hive for user $($user.Name) after $retryCount attempts."
                        break
                    }
                    else { 
                        Start-Sleep -Seconds (2 * $retryCount) # короткий sleep між спробами вивантажити профіль з реєєстру
                        $retryCount++
                    }
                }
            }
        }
    }
   
}

Write-Host "-----------------------------------------`n`n"

# за бажання можна об'єднати userProfilePath і $ntuserDatPath в 1 змінну - $ntuserDatPath = Join-Path -Path (Get-ItemPropertyValue -Path 
# "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$($user.SID.Value)" -Name "ProfileImagePath")
# -ChildPath "NTUSER.DAT". Але вона робить скрипт не дуже читабельним - довгувата трохи