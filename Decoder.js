var fs = require('fs'),
    Q = require('q');

var affixes = [];

/**
 * @param {string} line
 */
var parseLine = function (line) {
    line = line.trim();
    if (!line) {
        return;
    }

    line = line.replace(/ ?#.*$/, '');
    if (!line) {
        return;
    }
    var command = line.replace(/ {2,}/, ' ').split(' ');
    if (command[0] === 'SFX' || command[0] === 'PFX') {
        var type = command[0];
        var index = command[1];
    }

    /*
            if ($command[0] == 'SFX' || $command[0] == 'PFX') {
                $type = $command[0];
                $index = $command[1];
                if ($type != $prevType || $index != $prevIndex) {
                    $prevType = $type;
                    $prevIndex = $index;

                    $this->_affixes[$index] = array(
                        'type' => $type == 'SFX',
                        'connection' => $command[2],
                        'rules' => array()
                    );
                } else {
                    $this->_affixes[$index]['rules'][] = array(
                        'remove' => $command[2] == '0' ? '.' : $command[2],
                        'affix' => $command[3] == '0' ? '.' : $command[3],
                        'condition' => $command[4] == '0' ? '.' : $command[4]
                    );
                    if (isset($command[5])) {
                        die("Error in line: " . $line);
                    }
                }
            }

     */
};

var readAffixes = function (file) {
    console.log("Parsing .aff file...");

    var lines = file.split('\n');

    lines.forEach(function (line) {
        line = line.trim()
    });
};

var convertDictionary = function () {
};

var process = function () {
    console.log("Reading .aff file...");
    Q.nfcall(fs.readFile, "ru_RU.aff", "UTF-8")
        .then(readAffixes)
        .then(convertDictionary);
};

module.exports = process;
