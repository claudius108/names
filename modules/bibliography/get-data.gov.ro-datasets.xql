xquery version "3.1";

declare namespace http = "http://expath.org/ns/http-client";
declare namespace file = "http://exist-db.org/xquery/file";

let $base-url := "http://data.gov.ro/api/3/action/"
let $organization := "mapn"
let $output-collection := "/apps/nume/data/"
let $formats := ("xls", "json")

let $dataset-ids := json-doc($base-url || "organization_show?id=" || $organization || "&amp;include_datasets=true")?result?packages?*?id
let $bibliographic-records :=
    for $dataset-id in $dataset-ids
    let $resources := json-doc($base-url || "package_show?id=" || $dataset-id)?result?resources?*
    
    return
        for $resource in $resources

        let $resource-format := lower-case($resource?format)
        
        return
            if ($resource-format = $formats)
            then
                let $resource-name := $resource?name
                let $resource-id := "uuid-" || util:uuid($dataset-id)            
                let $download-url := $resource?romania_download_url
                let $http-request := <http:request method="get" href="{$download-url}" />
                let $file := http:send-request($http-request)[2]
                let $store-file := xmldb:store($output-collection || "bibliographic-works", $resource-id || "." || $resource-format, $file) 
                let $bibliographic-record := 
                    <TEI xmlns="http://www.tei-c.org/ns/1.0" xml:lang="ro" xml:id="{$resource-id}">
                    	<teiHeader>
                    		<fileDesc>
                    			<titleStmt>
                    				<title xml:lang="ro">{$resource-name}</title>
                    				<editor role="creator">Claudius Teodorescu</editor>
                    			</titleStmt>
                    			<publicationStmt>
                    				<publisher>Ratna Design SRL</publisher>
                    			</publicationStmt>
                    			<sourceDesc>
                    				<p>Born digital.</p>
                    			</sourceDesc>
                    		</fileDesc>
                    		<revisionDesc>
                    			<change when="{current-date()}"
                    				who="https://names.ro/documentation/editors.xml#claudius.teodorescu">CREATED: bibliographic entry.</change>
                    		</revisionDesc>
                    	</teiHeader>
                    	<text>
                    		<body>
                    			<biblStruct>
                    				<monogr>
                    					<editor>Ministerul Apărării Naționale</editor>
                    					<title xml:lang="ro" level="m">{$resource-name}</title>
                    					<imprint>
                    						<publisher>Ministerul Apărării Naționale</publisher>
                    						<date>{format-dateTime($resource?created, "[Y0001]-[M01]-[D01]")}</date>
                    					</imprint>
                    					<idno type="URI">{$download-url}</idno>
                    				</monogr>
                    			</biblStruct>
                    		</body>
                    	</text>
                    </TEI>
                
                return xmldb:store($output-collection || "bibliographic-records", $resource-id || ".xml", $bibliographic-record) 
            else ()

return $bibliographic-records