# HuaweiWatchfaceRepacker
How to use:

Open .hwt file like a zip archive, extract "com.huawei.watchface". In case if it's also zip archive, extract *.bin files from there and work with them.

Unpacking:

It's betetr to put "com.huawei.watchface" or bin file in the same directory with the tool. Run it on the command line:

HuaweiWatchfaceRepacker.exe unpack com.huawei.watchface

In case file name is different form "com.huawei.watchface", then specify its name, for example: HuaweiWatchfaceRepacker.exe unpack watchface.bin If you are lucky, an "input_file_name.out" directory will be created (for example, "com.huawei.watchface.out"), where all the images in .png format and the header (needed for repacking) will be extracted.

Repacking:

In the directory where the files were previously unpacked: do not touch anything, edit only the created png files without changing their image size, and only with an editor that supports the alpha channel. Save it without changing file name and it's format. Then run the tool on the command line:

HuaweiWatchfaceRepacker.exe pack folder_name

For example: HuaweiWatchfaceRepacker.exe pack com.huawei.watchface.out

Result file "com.huawei.watchface" containing the modified images will be created in the same folder. If "com.huawei.watchface" was not originally zip-archived, then simply replace it in original .hwt file. If com.huawei.watchface was an zip-archive, then rename generated "com.huawei.watchface" to .bin, replace related .bin file in original "com.huawei.watchface" and then replace it in original .hwt

Then install .hwt to device as usual. I had the opportunity to check only with my GT3. It runs on WinXP x32 and higher, developed in Delphi 11.

Good luck ;)
