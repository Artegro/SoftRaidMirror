[Console]::outputEncoding
echo "start"
rm c:\cmd\log.csv
rm c:\cmd\log1.csv
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "Press Enter for continue"
Read-Host
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
#$path="c:\cmd\"
#set /p $text="list disk" > C:\cmd\param.txt
#Write-Output "list disk"
#echo "" >> param.txt

#==============
# Get Disk
$param="list disk"
Out-File -FilePath c:\cmd\param1.txt -InputObject $param -Encoding ascii -NoNewline 
$log = diskpart.exe /s "c:\cmd\param.txt" # > c:\cmd\log.txt

$i = 0
foreach ($lg in $log){
    if ($i -gt 5 -and $i -ne 7){
        $a = 0
        $lg= $lg.Replace("###", "")
        echo $lg
        $lg1 = ""
        while ($a -le ($lg.Length-2)){
        #echo $a
            if ($lg[$a] -ne " "){
            #echo $lg[$a]
                $lg1 = $lg1 + $lg[$a]
            }
            elseif ($lg[$a] -eq " " -and $lg[$a+1] -ne " " -and $lg[$a+2] -ne " "){
            #echo $lg[$a]
                $lg1 = $lg1 + ";"
            }
        $a++
        }
        
        $lg1 = $lg1.Replace("  ", ";")
        
        echo $lg1 >> c:\cmd\log.csv
     }

    $i = $i+1
    
}
#==========
# Pars Disk
$Disk = Import-Csv -Path "c:\cmd\log.csv" -Delimiter ";"
foreach ($d in $Disk){
    if ($d.Disk -like "Disk0"){
        $d1 = $d.Disk.Replace("Disk", "")
$param = @"
select disk $d1
list partition
"@

        Out-File -FilePath c:\cmd\param1.txt -InputObject $param -Encoding ascii -NoNewline 
        $log = diskpart.exe /s "c:\cmd\param1.txt"
    }
   
}
#===========
# List Partition
$i = 0
foreach ($lg in $log){
    if ($i -gt 7 -and $i -ne 9){
        $a = 0
        $lg= $lg.Replace("###", "")
        $lg1 = ""
        while ($a -le ($lg.Length-2)){
        #echo $a
            if ($lg[$a] -ne " "){
            #echo $lg[$a]
                $lg1 = $lg1 + $lg[$a]
            }
            elseif ($lg[$a] -eq " " -and $lg[$a+1] -ne " " -and $lg[$a+2] -ne " "){
            #echo $lg[$a]
                $lg1 = $lg1 + ";"
            }
        $a++
        }
        $lg1 = $lg1.Replace("  ", ";")
        #echo $lg1
        #$lg1= $lg1.Replace("###", "")
                echo $lg1 >> c:\cmd\log1.csv
     }

    $i = $i+1
    
}

#=============
# clear disk 1
$d0 = Read-Host "enter number disk source"

$d = Read-Host "enter number disk destination"
$param = @"
select disk $d 
clean
convert gpt
select partition 1
delete partition override 
"@

        Out-File -FilePath c:\cmd\param1.txt -InputObject $param -Encoding ascii -NoNewline 
        diskpart.exe /s "c:\cmd\param1.txt"
        Start-Sleep 3


#============
# dublicate partition
$part = Import-Csv -Path "c:\cmd\log1.csv" -Delimiter ";"

Foreach ($p in $part){
    if ($p.Type -like "Recovery"){
       $size = $p.Size
       $met= $p.Offse
$param = @"
select disk $d 
create partition PRIMARY size=$size
format quick fs=ntfs
"@
       Out-File -FilePath c:\cmd\param1.txt -InputObject $param -Encoding ascii -NoNewline 
       diskpart.exe /s "c:\cmd\param1.txt"
       Start-Sleep 3

      $partition = $p.Partition.Replace("Partition", "")
$param = @"
select disk $d0
select partition $partition 
detail partition
"@ 
        Out-File -FilePath c:\cmd\param1.txt -InputObject $param -Encoding ascii -NoNewline 
       $log = diskpart.exe /s "c:\cmd\param1.txt"   
       foreach ($l in $log){
         if ( $l -like "Type*"){
             $id = $log[11].Replace("Type    : ","")
             echo $id
         }
       }#foreach ($l in $log)
$param = @"
select disk $d 
select partition $partition 
set id=$id
"@
       echo $param
      
       Out-File -FilePath c:\cmd\param1.txt -InputObject $param -Encoding ascii -NoNewline 
       diskpart.exe /s "c:\cmd\param1.txt"       
       Start-Sleep 3
        #========== Copy recovery data
$param = @"
select disk $d0
select partition $partition 
assign letter=q
select disk $d
select partition $partition
assign letter=z 
"@       
       
       Out-File -FilePath c:\cmd\param1.txt -InputObject $param -Encoding ascii -NoNewline 
       diskpart.exe /s "c:\cmd\param1.txt"              
       $copy = (robocopy.exe q:\ z:\ * /e /copyall /dcopy:t /xd /R:0 /w:0 )
       echo $copy

       Start-Sleep 3
       
                   
$param = @"
select disk $d0
select partition $partition 
remove
select disk $d
select partition $partition
remove 
"@       
       
       Out-File -FilePath c:\cmd\param1.txt -InputObject $param -Encoding ascii -NoNewline 
       diskpart.exe /s "c:\cmd\param1.txt"      
       Start-Sleep 3
           
    }# if ($p.Type -like "Recovery")

    elseif ($p.Type -like "System"){
        $partition = $p.Partition.Replace("Partition", "")
        $size = $p.Size
$param = @"
select disk $d 
create partition EFI size=$size
format fs=fat32 quick
"@
       Out-File -FilePath c:\cmd\param1.txt -InputObject $param -Encoding ascii -NoNewline 
       diskpart.exe /s "c:\cmd\param1.txt" 
       Start-Sleep 3

       #========= Copy EFI
$param = @"
select disk $d0
select partition $partition 
assign letter=p
"@       
       
       Out-File -FilePath c:\cmd\param1.txt -InputObject $param -Encoding ascii -NoNewline 
       diskpart.exe /s "c:\cmd\param1.txt" 
       echo $param
       Start-Sleep 3

$param = @"
select disk $d
select partition $partition
assign letter=s 
"@
       Out-File -FilePath c:\cmd\param1.txt -InputObject $param -Encoding ascii -NoNewline 
       diskpart.exe /s "c:\cmd\param1.txt" 
       echo $param
       Start-Sleep 3

       $s = (bcdedit /copy "{bootmgr}" /d "Windows Boot Manager Cloned")
       $s=$s.Replace("The entry was successfully copied to ","") 
       $s=$s.Replace(".","")  
       $bcded = (bcdedit /set "{063973c5-d0ac-11ed-b884-cfa59b967f58}" device partition=s: )
       echo $bcded
       $bcded = (bcdedit /export P:\EFI\Microsoft\Boot\BCD2)
       echo $bcded
       $bcded = (robocopy p:\ s:\ /e /R:0 /w:0)
       echo $bcded
       Rename-Item -Path "S:\EFI\Microsoft\Boot\BCD2" -NewName "BCD" 
       Remove-Item "P:\EFI\Microsoft\Boot\BCD2"   
       Start-Sleep 3

$param = @"
select disk $d0
select partition $partition 
remove
"@       
       
       Out-File -FilePath c:\cmd\param1.txt -InputObject $param -Encoding ascii -NoNewline 
       diskpart.exe /s "c:\cmd\param1.txt"      
       Start-Sleep 3

$param = @"    
select disk $d
select partition $partition
remove 
"@     
       
       Out-File -FilePath c:\cmd\param1.txt -InputObject $param -Encoding ascii -NoNewline 
       diskpart.exe /s "c:\cmd\param1.txt"      
       Start-Sleep 3

    }#if ($p.Type -like "System")

    elseif ($p.Type -like "Reserved"){
        $partition = $p.Partition.Replace("Partition", "")
        $size = $p.Size
$param = @"
select disk $d 
create partition MSR size=$size
"@
       Out-File -FilePath c:\cmd\param1.txt -InputObject $param -Encoding ascii -NoNewline 
       diskpart.exe /s "c:\cmd\param1.txt" 
    }#if ($p.Type -like "Reserved")
    else {

$param = @"
select disk $d0 
Convert dynamic
"@
Out-File -FilePath c:\cmd\param1.txt -InputObject $param -Encoding ascii -NoNewline 
diskpart.exe /s "c:\cmd\param1.txt"

$param = @"
select disk $d 
Conv dyn
"@
Out-File -FilePath c:\cmd\param1.txt -InputObject $param -Encoding ascii -NoNewline 
diskpart.exe /s "c:\cmd\param1.txt"

$param = @"
select disk $d0 
Select volume c
Add disk=$d
"@
Out-File -FilePath c:\cmd\param1.txt -InputObject $param -Encoding ascii -NoNewline 
diskpart.exe /s "c:\cmd\param1.txt"
    }

}

$param = @"
select disk $d0 
Convert dynamic
"@
Out-File -FilePath c:\cmd\param1.txt -InputObject $param -Encoding ascii -NoNewline 
diskpart.exe /s "c:\cmd\param1.txt"

$param = @"
select disk $d 
Conv dyn
"@
Out-File -FilePath c:\cmd\param1.txt -InputObject $param -Encoding ascii -NoNewline 
diskpart.exe /s "c:\cmd\param1.txt"

$param = @"
select disk $d0 
Select volume c
Add disk=$d
"@
Out-File -FilePath c:\cmd\param1.txt -InputObject $param -Encoding ascii -NoNewline 
diskpart.exe /s "c:\cmd\param1.txt"
#diskpart.exe /s "c:\cmd\param1.txt" > c:\cmd\log1.txt
#$log = Get-Content -Path "c:\cmd\log.txt"
#echo = $log.
#delete c:\cmd\log.txt


#======= Create morr Mirror 

$request= Read-Host - "Create anothe RAID MIRROR Y\N"

if ($request -like "Y"){
$param = @"
list disk
"@
Out-File -FilePath c:\cmd\param1.txt -InputObject $param -Encoding ascii -NoNewline 
diskpart.exe /s "c:\cmd\param1.txt"

$d0 = Read-Host "enter number disk source"

$d = Read-Host "enter number disk destination"

$param = @"
select disk $d0 
list volume
"@
Out-File -FilePath c:\cmd\param1.txt -InputObject $param -Encoding ascii -NoNewline 
diskpart.exe /s "c:\cmd\param1.txt"

$vol = Read-Host "enter volume"



$param = @"
select disk $d 
clean
convert gpt
"@

        Out-File -FilePath c:\cmd\param1.txt -InputObject $param -Encoding ascii -NoNewline 
        diskpart.exe /s "c:\cmd\param1.txt"
        Start-Sleep 3

$param = @"
select disk $d0 
Convert dynamic
"@
Out-File -FilePath c:\cmd\param1.txt -InputObject $param -Encoding ascii -NoNewline 
diskpart.exe /s "c:\cmd\param1.txt"

$param = @"
select disk $d 
Conv dyn
"@
Out-File -FilePath c:\cmd\param1.txt -InputObject $param -Encoding ascii -NoNewline 
diskpart.exe /s "c:\cmd\param1.txt"

$param = @"
select disk $d0 
Select volume $vol
Add disk=$d
"@
Out-File -FilePath c:\cmd\param1.txt -InputObject $param -Encoding ascii -NoNewline 
diskpart.exe /s "c:\cmd\param1.txt"

}
