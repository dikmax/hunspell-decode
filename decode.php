#!/usr/bin/php
<?php

class Decoder
{
    private $_affFile;
    private $_dicFile;
    private $_resFile;

    public function __construct()
    {
        $this->_affFile = fopen('ru_RU.aff', 'r');
        $this->_dicFile = fopen('ru_RU.dic', 'r');
        $this->_resFile = fopen('russian.dic', 'w');
    }

    public function process()
    {
        $this->_readAffixes();
        $this->_convertDictionary();
    }

    private function _readAffixes()
    {
        echo "Reading .aff file\n";

        $affixes = array();
        $prevType = $prevIndex = null;

        while ($line = fgets($this->_affFile)) {
            $line = trim($line);
            if (!$line) {
                continue;
            }
            $line = preg_replace('/ ?#.*$/', '', $line);
            if (!$line) {
                continue;
            }
            $line = preg_replace('/ {2,}/', ' ', $line);

            $command = explode(' ', $line);
            //echo "$line\n";

            if ($command[0] == 'SFX' || $command[0] == 'PFX') {
                $type = $command[0];
                $index = $command[1];
                if ($type != $prevType || $index != $prevIndex) {
                    $prevType = $type;
                    $prevIndex = $index;

                    $affixes[$index] = array(
                        'type' => $type == 'SFX',
                        'connection' => $command[2],
                        'rules' => array()
                    );
                } else {
                    $affixes[$index]['rules'][] = array(
                        'remove' => $command[2] == '0' ? '.' : $command[2],
                        'affix' => $command[3] == '0' ? '.' : $command[3],
                        'condition' => $command[4] == '0' ? '.' : $command[4]
                    );
                    if (isset($command[5])) {
                        die("Error in line: " . $line);
                    }
                }
            }
        }
    }

    private function _convertDictionary()
    {
        echo "Converting dictionary.\n";
        fread($this->_dicFile, 3);
        while ($line = fgets($this->_dicFile)) {
            $line = trim($line);
            if (is_numeric($line)) {
                continue;
            }
            if (strpos($line, '/') === false) {
                $this->_writeWord($line);
                continue;
            }
            list($word, $flagsString) = explode('/', $line, 2);
            $flags = str_split($flagsString, 2);
            $prefixes = array(array(array('condition' => '.', 'remove' => '.', 'affix' => '.')));
            $suffixes = array(array(array('condition' => '.', 'remove' => '.', 'affix' => '.')));
            foreach ($flags as $flag) {
                if (isset($affixes[$flag])) {
                    if ($affixes[$flag]['type']) {
                        $suffixes[] = $affixes[$flag]['rules'];
                    } else {
                        $prefixes[] = $affixes[$flag]['rules'];
                    }
                }
            }

            $newWords = array();
            foreach ($suffixes as $suffix) {
                foreach ($suffix as $rule) {
                    $newWord = $word;
                    if ($rule['condition'] != '.' || !preg_match('/' . $rule['condition'] . '$/u', $newWord)) {
                        if ($rule['remove'] != '.') {
                            $newWord = preg_replace('/' . $rule['remove'] . '$/u', '', $newWord);
                        }
                        if ($rule['affix'] != '.') {
                            $newWord .= $rule['affix'];
                        }
                    } else {
                        continue;
                    }
                    $newWords[] = $newWord;
                }
                /*foreach ($prefixes as $prefix) {

                }*/
            }
            $newWords = array_unique($newWords);
            foreach ($newWords as $newWord) {
                $this->_writeWord($newWord);
            }

        }
    }

    private function _writeWord($word) {
        fwrite($this->_resFile, $word . "\n");
    }
}

$decoder = new Decoder();
$decoder->process();
