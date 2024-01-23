    param (
        [string]$FeedUrl =  "https://drpodcast.nu/genstart/feed.xml",
        [string]$OutputFilename = "rss.xml"
    )

    try {
        # Download the Atom feed
        $webClient = New-Object System.Net.WebClient
        $feedXml = $webClient.DownloadString($FeedUrl)

        # Parse the Atom feed
        $reader = [System.Xml.XmlReader]::Create([System.IO.StringReader] $feedXml)
        $feed = [System.ServiceModel.Syndication.SyndicationFeed]::Load($reader)
        $feed.ImageUrl = New-Object System.Uri("https://asset.dr.dk/imagescaler/?protocol=https&server=api.dr.dk&file=%2Fradio%2Fv2%2Fimages%2Fraw%2Furn%3Adr%3Aradio%3Aimage%3A6593ba16565a59b45eeb8388&scaleAfter=crop&quality=70&w=336&h=336")

        if ($feed -ne $null) {
            # Iterate through each item in the feed
            foreach ($item in $feed.Items) {
                $itemUrl = $item.Links[1].Uri

                $httpClientHandler = New-Object System.Net.Http.HttpClientHandler
                $httpClientHandler.AllowAutoRedirect = $false
                $httpClient = New-Object System.Net.Http.HttpClient -ArgumentList $httpClientHandler

                $response = $httpClient.GetAsync($itemUrl).Result

                if ($response.StatusCode -eq [System.Net.HttpStatusCode]::Found) {
                    $redirectedUrl = $response.Headers.Location.ToString()

                    # Replace "mp4" with "mp3" in the URL
                    $modifiedUrl = $redirectedUrl -replace 'mp4', 'mp3'
                    Write-Output $item.Title.Text
                    # Update the URL in the enclosure
                    $newEnclosureUrl = New-Object System.Uri($modifiedUrl)
                    $item.Links[1] = New-Object System.ServiceModel.Syndication.SyndicationLink($newEnclosureUrl)
                } else {
                    Write-Output "Request was not redirected. Status code: $($response.StatusCode)"
                }
            }

            # Create an XmlWriter for the specified output filename
            $rssWriter = [System.Xml.XmlWriter]::Create($OutputFilename)

            # Create an Rss20FeedFormatter using the feed object
            $rssFormatter = New-Object System.ServiceModel.Syndication.Rss20FeedFormatter($feed)

            # Write the feed to the XmlWriter
            $rssFormatter.WriteTo($rssWriter)

            # Close the XmlWriter
            $rssWriter.Close()

            Write-Output "Updated feed saved to $OutputFilename."
        }
    } catch {
        Write-Host "An error occurred: $_.Exception.Message"
    }
