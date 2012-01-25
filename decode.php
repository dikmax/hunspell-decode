#!/usr/bin/php
<?php

class Decoder
{
    private $_affFile;
    private $_dicFile;
    private $_resFile;

    private $_affixes;

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

        $this->_affixes = array();
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
            /*$prefixes = array(array(array('condition' => '.', 'remove' => '.', 'affix' => '.')));
            $suffixes = array(array(array('condition' => '.', 'remove' => '.', 'affix' => '.')));*/
            $prefixes = array();
            $suffixes = array();
            foreach ($flags as $flag) {
                if (isset($this->_affixes[$flag])) {
                    if ($this->_affixes[$flag]['type']) {
                        $suffixes[$flag] = $this->_affixes[$flag]['rules'];
                    } else {
                        $prefixes[$flag] = $this->_affixes[$flag]['rules'];
                    }
                }
            }

            $result = array($word);
            foreach ($suffixes as $flag => $suffix) {
                $newWords = $this->_applySuffix($word, $suffix);
                $result = array_merge($result, $newWords);
                foreach ($prefixes as $prefix) {
                    $newWords2 = $this->_applyPrefix($newWords, $prefix, $flag);
                    $result = array_merge($result, $newWords2);
                }
            }

            foreach ($prefixes as $flag => $prefix) {
                $newWords = $this->_applyPrefix($word, $prefix);
                $result = array_merge($result, $newWords);
                foreach ($suffixes as $suffix) {
                    $newWords2 = $this->_applySuffix($newWords, $suffix, $flag);
                    $result = array_merge($result, $newWords2);
                }
            }

            $result = array_unique($result);
            foreach ($result as $newWord) {
                $this->_writeWord($newWord);
            }

        }
    }

    private function _applySuffix($words, $suffix, $prefixFlag = null)
    {
        if (!is_array($words)) {
            $words = array($words);
        }
        $result = array();
        foreach ($words as $word) {
            foreach ($suffix as $rule) {
                if (strpos($rule['affix'], '/') !== false) {
                    list($replace, $flagsString) = explode('/', $rule['affix'], 2);
                    $flags = str_split($flagsString, 2);
                    if (!in_array($prefixFlag, $flags)) {
                        continue;
                    }
                } else {
                    $replace = $rule['affix'];
                }
                $newWord = $word;
                if ($rule['condition'] == '.' || preg_match('/' . $rule['condition'] . '$/u', $newWord)) {
                    if ($rule['remove'] != '.') {
                        $newWord = preg_replace('/' . $rule['remove'] . '$/u', '', $newWord);
                    }
                    if ($replace != '.') {
                        $newWord .= $replace;
                    }
                } else {
                    continue;
                }
                $result[] = $newWord;
            }
        }

        return array_unique($result);
    }

    private function _applyPrefix($words, $prefix, $suffixFlag = null)
    {
        if (!is_array($words)) {
            $words = array($words);
        }
        $result = array();
        foreach ($words as $word) {
            foreach ($prefix as $rule) {
                if (strpos($rule['affix'], '/') !== false) {
                    list($replace, $flagsString) = explode('/', $rule['affix'], 2);
                    $flags = str_split($flagsString, 2);
                    if (!in_array($suffixFlag, $flags)) {
                        continue;
                    }
                } else {
                    $replace = $rule['affix'];
                }
                $newWord = $word;
                if ($rule['condition'] == '.' || preg_match('/^' . $rule['condition'] . '/u', $newWord)) {
                    if ($rule['remove'] != '.') {
                        $newWord = preg_replace('/^' . $rule['remove'] . '/u', '', $newWord);
                    }
                    if ($replace != '.') {
                        $newWord = $replace . $newWord;
                    }
                } else {
                    continue;
                }
                $result[] = $newWord;
            }
        }

        return array_unique($result);
    }

    private function _writeWord($word) {
        fwrite($this->_resFile, $word . "\n");
    }
}

$decoder = new Decoder();
$decoder->process();
