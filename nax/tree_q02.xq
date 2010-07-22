(: This query was taken from
   'Galax' (http://www.galaxquery.org/) :)
declare namespace fx="www.fx.org";
declare function fx:trim
  ( $arg as xs:string? )  as xs:string {

   replace(replace($arg,'\s+$',''),'^\s+','')
 };
<res> {
let $lines := //line[fn:contains(.//div[fn:starts-with(@id, "staticurl")]//text(), "stream.asp")]
return for $l in $lines(://line
	where (:fn:exists($l//div[fn:starts-with(@id,"trackartists")]) and :)fn:contains($l//div[fn:starts-with(@id, "staticurl")]//text(), "stream.asp"):)
	return let
		$title:=fx:trim(if (fn:exists($l//div[fn:starts-with(@id, "staticurl")]/preceding-sibling::b)) then $l//div[fn:starts-with(@id, "staticurl")]/preceding::b[1]//text() else fn:substring(if (fn:exists($l//div[fn:starts-with(@id,"trackartists")])) then $l/text()[1] else $l/text(),3)),
		$target:=fn:concat(fn:index-of($lines,$l), " ", fn:translate($title,":!?&amp;&quot;/","...___"),".wma"),
		$album:=
			if (fn:empty($l//div[fn:starts-with(@id, "staticurl")]/preceding-sibling::b))
				then fn:concat(" __  --album= __ ", $l//div[fn:starts-with(@id, "staticurl")]/preceding::b[1]//text())
			else if (fn:empty($l//div[fn:starts-with(@id,"trackartists")]) )
				then fn:concat(" __  --album= __ ", $l/preceding::b[1]/a/text())
			else "",
		$artists:=for $a in (if (fn:exists($l//div[fn:starts-with(@id,"trackartists")])) then $l else $l/preceding-sibling::line)//div[fn:starts-with(@id,"trackartists")][fn:last()]//text()
		where fx:trim($a) != ""
		return fn:concat(if ($a/parent::node() is $a/ancestor-or-self::a and $a/parent::node() != $a/ancestor::div/a[1])
			then ";" else "", fx:trim($a))

	return fn:concat("
[ -e  __ ", $target, " __  ] || (
 file=$(./dl  __ br=64&amp;tl=",fn:substring($l//div[fn:starts-with(@id, "staticurl")]/@id,11), " __ )
 [ -z  __ $file __  ] &amp;&amp; exit 1
(
  echo $file >>  __ $1orig __ 
  eyeD3  __ $file __  --set-encoding=utf8 --artist= __ ", fn:string(text{$artists}), $album, " __  --title= __ ", $title, " __ 
  mv  __ $file __   __ ", $target, " __ 
 )
)"),"
"}
</res>
