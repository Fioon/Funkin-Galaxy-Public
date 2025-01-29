class Language {
	private static var haxeInterp:hscript.Interp = new hscript.Interp(); private static var haxeParser:hscript.Parser = new hscript.Parser();
    static var langCache:Map<String, Map<String, String>> = [];
    public static function getString(stringToLookFor:String, ?language:String = "idkMan", ?fromLua:Bool = false):String {
        if (language == "idkMan") language = ClientPrefs.language;
        if (langCache.exists(language) && langCache.get(language).exists(stringToLookFor))
        {
            return langCache.get(language).get(stringToLookFor);
        } else {
            var daMap:Map<String, String> = (langCache.exists(language) ? langCache.get(language) : []);
            var json = haxe.Json.parse(sys.io.File.getContent(SUtil.getPath() + "assets/languages/" + language + ".json"));
            haxeInterp.variables.set('json', json);
		    var toParse = haxeParser.parseString('return json.${stringToLookFor};');
		    var gotTranslated = haxeInterp.execute(toParse);
            daMap.set(stringToLookFor, gotTranslated);
            langCache.set(language, daMap);
            return (gotTranslated != null ? gotTranslated : "?");
        }
        return "?";
    }
    public static function clearCache() {langCache = [];}
}
