

$enabledUsers = Get-LocalUser | Where-Object { $_.Enabled -eq $true } # список всех локальных пользователей на компьютере, которые включены (Enabled)

Write-Host "`n`nUsername        New_MessageDuration" # дает эстетически оптимальный вывод измененных значений MessageDuration
Write-Host "-----------------------------------"

$newMessageDuration = 300

foreach ($user in $enabledUsers) {
    # в ProfileList лежат профили пользователей в виде директорий соответствующий SID пользователя. В ProfileImagePath лежит значение=домашняя директория пользователя
    $userProfilePath = Get-ItemPropertyValue -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$($user.SID.Value)" -Name "ProfileImagePath"
    
    # строка создает полный путь к файлу NTUSER.DAT пользователя. NTUSER.DAT - это файл реестра для каждого пользователя.
    $ntuserDatPath = Join-Path -Path $userProfilePath -ChildPath "NTUSER.DAT"
    $registryPath = "Registry::HKEY_USERS\$($user.SID.Value)\Control Panel\Accessibility" # это уже путь к разделу реестра с загруженными разделами пользователей
    
    # проверяет загружен ли профиль пользователя в HKEY_USERS. работает с пользователями, которые подключены к серверу в момент запуска скрипта
    # если путь существует - значит пользователь есть в HKEY_USERS, значит можно напрямую с HKEY_USERS редактировать MessageDuration 
    if (Test-Path $registryPath) { 
        Set-ItemProperty -Path $registryPath -Name "MessageDuration" -Value $newMessageDuration
        Write-Host "$($user.Name)            $($newMessageDuration)"
    }
# в HKEY_USERS находятся только пользователи с активным сеансом с сервером.неподключенным пользователям нельзя отредактировать значение MessageDuration в в HKEY_USERS,
# поэтому в их случае нужно специально загружать их профиль пользователя в HKEY_USERS
     
    elseif (Test-Path $ntuserDatPath) { # проверяет, есть ли профиль пользователя в его домашней директории. команда в первой строке скрипта подтягивает только 
        # существующих активированных пользователей, а они или в HKEY_USERS (тогда выполняется первая проверка условия if) или нет.Если нет-выполняется эта проверка,
        # которая подтверждает что у пользователя есть профиль в домашней директории, а значит он является зарегистрированным пользователем на сервере. 
        
        try {                           
            $null = reg load "HKU\$($user.SID.Value)" $ntuserDatPath # чат говорит, что если результат команды присвоить переменной "null", то ее вывод не отобразиться 
            # в консоли. или может быть вывод в принципе не отобразиться в консоли, если присвоить его переменной (а null здесь для интерактивного понимания того, что
            # вывод не нужен)
            Set-ItemProperty -Path $registryPath -Name "MessageDuration" -Value $newMessageDuration # тут уже обычное редактирование ключа в HKEY_USERS
            Write-Host "$($user.Name)            $($newMessageDuration)"
        }
        finally {
            # цикл используется для повторных попыток выгрузки профиля пользователя из реестра. Если выгрузка не удается, он ждет некоторое время и пытается снова. 
            # Цикл будет продолжаться, пока выгрузка не будет успешной, или пока не будет сделано три неудачные попытки.
            $retryCount = 0
            while ($true) {
                try {
                    $null = reg unload "HKU\$($user.SID.Value)" # выгружает профиль пользователя с HKEY_USERS.если выгрузки не будет - 
                    break                                                                                                       # изменения профиля могут не сохраниться
                }
                catch {
                    if ($retryCount -ge 3) {
                        Write-Host "Failed to unload registry hive for user $($user.Name) after $retryCount attempts."
                        break
                    }
                    else {
                        Start-Sleep -Seconds (2 * $retryCount)
                        $retryCount++
                    }
                }
            }
        }
    }
}

Write-Host "-----------------------------------`n`n"
