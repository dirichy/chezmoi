local DIR=$(dirname $(realpath $0))
baipan(){
    __bypypath="$HOME/.bypy/cache"
    __bypypwd="/"
    binit(){
        python "$DIR/bs.py"
    }

    bcd() {
        if [ -n "$1" ]; then
            if [ -d "$__bypypath$__bypypwd/$1" ]; then
                __bypypwd=`realpath "$__bypypath$__bypypwd/$1"`
                __bypypwd=${__bypypwd#$__bypypath}
            else
                echo "远程目录$__bypypwd/$1不存在"
            fi
        else
            __bypypwd="/"
        fi
    }
    _bcd() {
        _arguments '1:百度网盘路径:_path_files -W "$__bypypath$__bypypwd" -/'
    }

    bcp() {
        if [ -e "$__bypypath$__bypypwd/$1" ]; then
            bypy --downloader aria2c download "$__bypypwd/$1" "$2"
        else
            echo "远程文件$__bypypath$__bypypwd/$1不存在"
        fi
    }

    _bcp() {
        _arguments '1:百度网盘路径:_path_files -W "$__bypypath$__bypypwd"' \
            '2:本地路径:_path_files'
    }

    bsync() {
        if [ -e "$__bypypath$__bypypwd/$1" ]; then
            bypy --downloader aria2c download "$__bypypwd/$1" "$__bypypath$__bypypwd/$1"
        else
            echo "远程文件$__bypypath$__bypypwd/$1不存在"
        fi
    }

    _bsync() {
        _arguments '1:百度网盘路径:_path_files -W "$__bypypath$__bypypwd"'
    }
    bls(){
        ls -l "$__bypypath$__bypypwd/$1"
    }

    compdef _bcp bcp
    compdef _bcd bcd
    compdef _bcd bls
}
