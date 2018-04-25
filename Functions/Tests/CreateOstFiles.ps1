$path = 'D:\jimm\ost'

New-Item -Path (Join-Path $path 'test.ost') -ItemType 'File'
New-Item -Path (Join-Path $path 'test(1).ost') -ItemType 'File'
New-Item -Path (Join-Path $path 'test(2).ost') -ItemType 'File'
New-Item -Path (Join-Path $path 'test(3).ost') -ItemType 'File'

New-Item -Path (Join-Path $path 'blah.ost') -ItemType 'File'
New-Item -Path (Join-Path $path 'blah(1).ost') -ItemType 'File'
New-Item -Path (Join-Path $path 'blah(2).ost') -ItemType 'File'
New-Item -Path (Join-Path $path 'blah(3).ost') -ItemType 'File'
New-Item -Path (Join-Path $path 'blah(4).ost') -ItemType 'File'
New-Item -Path (Join-Path $path 'blah(5).ost') -ItemType 'File'