require 'chunky_png'

xantgenos = false

def bytesToNum(bytes)
    num = 0
    counter = 0.upto((bytes.size-1)).map {|b| b}
    bytes.size.times do |t|
        num += bytes[t] << (counter[t] * 8)
    end
    return num
end

def numToBytes(num,count)
    bytes = Array.new
    counter = 0.upto((count-1)).map {|b| b}
    counter.size.times do |t|
        bytes.push ((num >> (counter[t] * 8)) & 0xff)
    end
    return bytes
end

def read_file(path)
    return IO.binread(path).bytes
end

def combine_files(files_arr)
    header = files_arr[0][0..0x17]
    width = 0
    files_arr.each {|file| width += bytesToNum file[0x14..0x15]}
    header[0x14] = width
    combined_file = header + files_arr[0][0x18..-1] + files_arr[1][0x18..-1]
    return combined_file
end

def unpack_data(file,count)
    offset = 0x18
    word_prev = [0,0]
    unpack_bytes = []
    while unpack_bytes.length < count && offset < file.size do
        repeats = 1
        word = [file[offset],file[offset+1]]
        if word[0] == 0x64 && word[1] > 0
            repeats = word[1]
            word = word_prev
        elsif word[0] == 0x64 && word[1] == 0
            offset += 1
            word[1] = file[offset+1]
            word_prev = word
        else
            word_prev = word
        end
        repeats.times do
            word.each {|byte| unpack_bytes.push byte}
        end
        offset += 2
    end
    return [unpack_bytes,offset]
end

def get_colors(file,offset,bpp)
    colors = Array.new
    if offset < file.size
        16.times {|t|
            cOffset = offset + (t*4)
            red = file[cOffset+1]
            red = (red << 4) + red
            green = file[cOffset+2]
            green = (green << 4) + green
            blue = file[cOffset+3]
            blue = (blue << 4) + blue
            colors.push ChunkyPNG::Color.rgb(green,blue,red)
        }
    elsif bpp == 1
        colors = ["black","white"]
    else
        16.times {|t|
            colors.push ChunkyPNG::Color.rgb((t+t << 4),(t+t << 4),(t+t << 4))
        }
    end
    return colors
end

def read_image(files)
    files_arr = []
    files.each {|file| files_arr.push read_file file }
    header = files_arr[0][0..0x17]
    height = bytesToNum header[0x16..0x17]
    xPos = (bytesToNum header[0x10..0x11])*8
    yPos = bytesToNum header[0x12..0x13]
    if header[0x0e] == 0x10
        bpp=4
    elsif header[0x0e] == 0x08
        bpp=3
    elsif header[0x0e] == 0x0e
        bpp=1
    else
        puts "Unknown bit depth: 0x%02x" % header[0x0e]
        exit
    end
    data_dict = []
    colors = []
    files_arr.each {|file|
        width = file[0x14]
        unpack_size = width*height*4
        image_data = unpack_data(file,unpack_size)
        colors = get_colors(file,image_data[1],bpp)
        data_dict.push image_data[0]
    }
    return [height,xPos,yPos,bpp,colors,data_dict]
end

def draw_image(image_data)
    height = image_data[0]
    xPos = image_data[1]
    yPos = image_data[2]
    bpp = image_data[3]
    colors = image_data[4]
    image = ChunkyPNG::Image.new(640, 400, ChunkyPNG::Color::TRANSPARENT)
    image_data[5].each do |imgBytes|
        pixelSum = imgBytes.size/bpp
        pixelSum.times do |bOffset|
            tile = imgBytes[bOffset]
            8.times do |bit|
                pixel = 0
                bpp.times do |m|
                    pixel += imgBytes[(bOffset+(pixelSum*m))][7-bit] << (m)
                end
                image[xPos,yPos] = colors[pixel]
                xPos += 1
            end
            yPos += 1
            xPos -= 8
            if yPos >= image_data[2]+height
                yPos = image_data[2]
                xPos += 8
            end
        end
        yPos = image_data[2]
    end
    return image
end

files = Dir.glob("import/*.PG4", File::FNM_CASEFOLD).sort
exit if files.size < 1

idx = 0
while idx < files.size do
    if files[idx].split("/")[1][0].match(/[U-Z]/) && files[idx].split("/")[1][2] == "0" && files[idx+1].split("/")[1][2] == "1" && xantgenos
        puts files[idx]+' '+files[idx+1]
        file = combine_files [read_file(files[idx]),read_file(files[idx+1])]
        image_data = read_image([files[idx], files[idx+1]])
        file_name = files[idx].split("/")[1][0..1]+".png"
        idx += 1
    else
        puts files[idx]
        file = read_file files[idx]
        image_data = read_image([files[idx]])
        file_name = files[idx].split("/")[1].split(".")[0]+".png"
    end
    idx += 1
    picture = draw_image image_data
    picture.save("export/"+file_name, :interlace => true)
end
