// vim: set ft=rb:
package lexah.cli;
using Lambda;
using StringTools;


import sys.FileSystem;
import lexah.tools.Error;
import lexah.tools.FolderReader;
import lexah.transpiler.Transpiler;

class TranspilerCommand{
/**
 * @var files
 *
 * Size of the files (file_size) for files
 **/
private var files : Map<String, Int>;
private var dest: String;
private var src : String;
public var response : String;

/**
 * @param String src   Source file or directory
 * @param String ?dest Destination file or directory (optional)
**/
public function new(src: String, ?dest: String){
    this.src = src;
    this.dest = dest;
    this.files = new  Map<String, Int>();
}

/**
 * Transpile a file or a whole directory
 *
 * @param lexahOnly Bool Must only copy to the dest directory, raxe files
 *
 * @return Bool transpilation has been done or not
**/
public function transpile(lexahOnly: Bool) : Bool{
    var src = this.src;
    var dest = this.dest;
    var dir = src;

    // Transpile one file
    if( !FileSystem.isDirectory(this.src) ) {
        var oldFileSize : Int = this.files.get(this.src);
        var currentSize : Int = FileSystem.stat(this.src).size;

        if( oldFileSize != currentSize ) {
            var result = transpileFile(dest, src);

            if( dest == null ) {
                this.response = result;
            }else{
                FolderReader.create_file(dest, result);
            }

            this.files.set(this.src, currentSize);
            return true;
        }

        return false;
    // Transpile a whole folder
    }else{
        var files = FolderReader.get_files(src);
        var hasTranspile : Bool = false;

        // To have the same pattern between src and dest (avoid src/ and dist instead of dist/)
        if( src.endsWith("/") ) {
            src = src.substr(0, src.length - 1);
        }

        if( dest == null ) {
            dest = src;
        }else if( dest.endsWith("/") ) {
            dest = dest.substr(0, dest.length - 1);
        }

        var currentFiles = new  Map<String, Int>();
        for( file in files.iterator() ) {
            var oldFileSize : Int = this.files.get(file);
            var currentSize : Int = FileSystem.stat(file).size;

            if( oldFileSize != currentSize && (!lexahOnly || isLexahFile(file)) ) {
                var newPath = this.getDestinationFile(file, src, dest);

                // If it's a lexah file, we transpile it
                if( isLexahFile(file) ) {
                    var result = transpileFile(dir, file);
                    FolderReader.create_file(newPath, result);
                    this.files.set(file, currentSize);

                // If it's not a lexah file, we just copy/past it to the new folder
                }else{
                    FolderReader.copy_file_system(file, newPath);
                }

                this.files.set(file, currentSize);
                hasTranspile = true;
            }

            currentFiles.set(file, currentSize);
        }

        for( key in this.files.keys() ) {
            if( currentFiles.get(key) == null ) {
                this.files.remove(key);
                FileSystem.deleteFile(this.getDestinationFile(key, src, dest));
            }
        }

        return hasTranspile;
    }

    return false;
}

/**
 * Transpile one file
 *
 * @param String file Transpile a file and returns its content
 *
 * @return String content
**/
public function transpileFile(dir : String, file: String): String{
    var trans = new  Transpiler();
    return trans.transpile(dir != null ? dir : Sys.getCwd(), file);
}

/**
 * Checks if the given file is a raxefile
**/
public function isLexahFile(filename: String): Bool{
    return filename.endsWith(".lxa");
}

/**
 * Get the path the destination file
 *
 * @param String file Path to the file
 * @param String src  Source directory
 * @param String dest Destination directory
 *
 * @return String destination file path
**/
public function getDestinationFile(file: String, src: String, dest: String) : String{
    var parts : Array<String> = file.split('/');
    var fileName : String = parts.pop();

    var newPath = parts.join("/") + "/" + fileName.replace(".lxa", ".hx");

    if( (dest != null) ) {
        newPath = newPath.replace(src, dest);
    }

    return newPath;
}

}