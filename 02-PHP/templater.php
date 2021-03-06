<?php


//---------------------------------------------------------
// This class render and configure template
//---------------------------------------------------------
//  VERSION: 1.2 (2014.04.10)
// 
//	USAGE example:
//
//	core\templater::render();
//	__construct: When initialized, we should assign template name and get content of TPL-file in variable
//	Data puts in variables
//	render(): When we calling render() method, we calling CheckCache method to check availability of cache file
//	If cache exist - just include it, if no - parse cache with Parse() method.
//	CheckCache: Checking cache file existence
//	Parse(): Parse template file
//	ParseBlock():Parse block to replace it with proper content
//	createCache(): Creating cache of TPL file on disk

namespace core;

class templater {

	private static $templatePath;
	private $template;
	private $templateName;
	private $cacheFileName;
	private $fullCacheFileName;
	private $data;
	private $pat;

	//---------------------------------------------------------
	// Constructor
	//---------------------------------------------------------
	
	public function __construct($template,$data=array()) {

		// Assign template dir variable

		$this -> templateName = str_replace("\\", "/", $template);

		$this -> templatePath = settings::$settings['tpl']['dir'] . $this -> templateName . settings::$settings['tpl']['extension'];

		if (!file_exists($this -> templatePath)){ echo "Error loading tpl ".$this -> templatePath; exit; }

		// Set this data as empty array
		$this -> data = array();

		$this -> setData($data);

		$this -> SetPCRE();
		
	}

	//---------------------------------------------------------
	// Set pcre templates for proper block extractions
	//---------------------------------------------------------

	private function SetPCRE(){

		// Simple PCRE to extract full blocks

		// Simple variables blocks
		// {$content}

		$this->pat['var'] = '#{\$([\a-zA-Z\':\\\\0-9]+)}#';

		// Included tpl
		// {tpl:highLevel}
		// {tpl:index/menu}
		
		$this->pat['tpl'] = '#{tpl:([\a-zA-Z\':\\\\0-9]+)}#';

		// If (start)
		// {if $bla=='do'}
		// {if $bla!='do'}

		$this->pat['if']="%({)if ([0-9a-zA-Z |&\$'\[\]!=><]+)(})%";

		// else
		// {else}
		$this->pat['else']="%{else}%";

		// elseif
		// {elseif $bla<2 && bl==20}
		$this->pat['elseif']="%({)elseif ([0-9a-zA-Z |&\$'\[\]!=><]+)(})%";

		// End if
		// {/if}
		$this->pat['endif']="%{\/if}%";

		// ForEach
		// {foreach $myArray as $foo}
		$this->pat['foreach']="%{foreach ([\$ a-zA-Z0-9\['\]\"]+)}%";

		// End foreach 
		// {/foreach}
		$this->pat['endforeach']="%{\/foreach}%";



	}

	//---------------------------------------------------------
	// Render current template
	//---------------------------------------------------------

	public function render( $mode=0 ){

		// extract data array 
		if(count($this->data)>0){
			extract($this -> data, EXTR_PREFIX_SAME, "wddx");
		}
		if( !$this -> checkCache() ) {

			// Parse template

			$this -> parse();
			
		} else {

			// Do nothing

		}

		ob_start();
		include $this -> fullCacheFileName;
		$bufferedcontent=ob_get_contents();
		ob_end_clean();

		// Depend on mode, returns proper result

		switch ($mode) { 

			case 0: return $bufferedcontent;

			case 1: echo $bufferedcontent;

			case 2:	return file_get_contents($this -> fullCacheFileName);

			case 3: return $this -> fullCacheFileName;

		}

	}

	//---------------------------------------------------------
	// Set data function
	//---------------------------------------------------------

	public function setData($data){
		// ! IMPORTANT. array_merge arguments rder is important!!!
		$this -> data = array_merge($this -> data,$data);
	}
	//---------------------------------------------------------
	// Check cache
	//---------------------------------------------------------

	private function checkCache(){

		$this -> getCacheName();

		if(file_exists($this -> fullCacheFileName)) {

			return 1;

		} else {

			return 0;
		}


	}

	//---------------------------------------------------------
	// Set cache name and paths
	//---------------------------------------------------------

	private function getCacheName(){

		// Get cache file modification time

		$templateTime = filemtime($this->templatePath);

		// Make filename of possible existing cache file

		$pathToTpl = dirname($this -> templateName);

		$this -> cacheFileName = $pathToTpl.'/'.$templateTime.'__'.basename($this -> templateName);

		$this -> fullCacheFileName = settings::$settings['cache']['dir'].$this->cacheFileName;


	}


	//---------------------------------------------------------
	// Extract all blocks for parsing
	//---------------------------------------------------------
	
	private function parse(){

		$array=array();

		// Get template content to variable to begin parsing

		$this -> template = file_get_contents($this->templatePath);

		foreach ($this->pat as $tpl) {
			preg_match_all($tpl,$this->template,$arrayRes);
			$array=array_merge($array,$arrayRes[0]);
		}

		//echo "<pre>";
		//print_r($array);
		//echo "</pre>";

		//---------------------------------------------------------
		// Run parsing per block
		//---------------------------------------------------------

		foreach ($array as $key) {

			// Remove { and } in block content to parse 

			//$valkey = str_replace(array("{","}"),array("","") , $key);

			$valkey = $key;

			// Run Parse block function

			$this -> parseBlock($valkey);

			// Template replacing
			
			$this -> template = str_replace($key,$valkey, $this -> template);

		}

		$this -> createCache();

	}


	//---------------------------------------------------------
	// Create cache from parsing
	//---------------------------------------------------------

	private function createCache(){

		// Get directory of template for create full paths structure in cache directory

		$pathToTpl = dirname($this -> fullCacheFileName);

		// Split it by slash

		preg_match_all("{[a-zA-Z0-9]+}", $pathToTpl,$needles);

		$emptyDir = "";

		foreach($needles[0] as $dir) {

			if($emptyDir == ""){

				$emptyDir = $dir."/";

			} else {

				$emptyDir = $emptyDir."/".$dir;

			}			

			if(file_exists($emptyDir."/")){

				// Do nothing!
				

			} else {

				mkdir($emptyDir."/");

			}
		}

		// Create new Cache file

		$newCacheFile = fopen($this -> fullCacheFileName,"x");

		// Write to new Cache file

		fwrite($newCacheFile,$this -> template);

	}

	//---------------------------------------------------------
	// Parse blocks functions by the templates
	//---------------------------------------------------------

	private function parseBlock(&$block=""){

		// If the block is include

		$this->parseValue($block);
		
		$this->parseTpl($block);

		$this->parseIfElse($block);

		$this->parseIfElseIf($block);

		$this->parseElse($block);

		$this->parseEndif($block);

		$this->parseForEach($block);

		$this->parseEndForEach($block);


	}

	private function parseValue(&$block=''){

		if(preg_match($this->pat['var'], $block)){

			$block = str_replace(array("{","}"),array("","") , $block);

			$block = '<? echo '.$block.'; ?>';

		}
	}

	private  function parseTpl(&$block=''){

		if(preg_match($this->pat['tpl'], $block)){

			$block = str_replace(array("{","}"),array("","") , $block);

			$blockrepl = preg_replace("/tpl:/", "", $block);

			$templ =  new templater($blockrepl);

			// Temporary result
			/* $block = '<? include "'.$templ -> render(3).'"; ?>'; */

			$block = '<? $templ = new core\templater(\''.$blockrepl.'\'); include $templ -> render(3); ?>';

		}
	}

	//---------------------------------------------------------
	// Parse blocks structures IFELSE FOREACH
	//---------------------------------------------------------

	private function parseIfElse(&$block=''){

		$arr=array();

		if(preg_match($this->pat['if'], $block,$arr)){

			// Replace bracing
			$block = str_replace(array("{","}"),array("<? "," ?>") , $block);

			// Add skobki
			$block = str_replace($arr[2],"(".$arr[2]."):", $block);
		}

	}

	private function parseElse(&$block=''){

		if(preg_match($this->pat['else'], $block)){

			$block = str_replace(array("{","}"),array("<? ",": ?>") , $block);

		}
	}

	private function parseIfElseIf(&$block=''){

		$arr=array();

		if(preg_match($this->pat['elseif'], $block,$arr)){

			// Replace bracing
			$block = str_replace(array("{","}"),array("<? "," ?>") , $block);

			// Add bracing
			$block = str_replace($arr[2],"(".$arr[2]."):", $block);
		}

	}

	private function parseEndif(&$block=''){

		if(preg_match($this->pat['endif'], $block,$ar)){

			$block = str_replace($ar[0],"<? endif; ?>", $block);

		}
	}

	//---------------------------------------------------------
	// Parse blocks FOREACH
	//---------------------------------------------------------

	private function parseForEach(&$block=''){

		$arr=array();

		if(preg_match($this->pat['foreach'], $block,$arr)){

			// Replace bracing
			$block = str_replace(array("{","}"),array("<? "," ?>") , $block);

			// Add bracing
			$block = str_replace($arr[1],"(".$arr[1]."):", $block);
		}

	}

	private function parseEndForEach(&$block=''){

		if(preg_match($this->pat['endforeach'], $block,$ar)){

			$block = str_replace($ar[0],"<? endforeach; ?>", $block);

		}
	}

}


?>
