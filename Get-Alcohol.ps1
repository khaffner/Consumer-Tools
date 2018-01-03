Function Get-Alcohol {
    [CmdletBinding()]
    Param (
        [ValidateSet('Vinmonopolet','Systembolaget')][string[]]$Source = ('Vinmonopolet','Systembolaget')
    )

    Begin {
        $AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
        [System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
        $ErrorActionPreference = 'stop'

        class Product {
            [string]$Source
            [long]$ProductNumber
            [string]$Name
            [int]$Price
            [int]$Volume
            [int]$PricePerLiter
            [string]$Category
            [string]$Container
            [int]$AlcoholPercentage
        }
    }
    Process {
        $ProductArray = @()
        if($Source -contains 'Vinmonopolet') {
            $ProductsRawVinmonopoletUrl = 'https://www.vinmonopolet.no/medias/sys_master/products/products/hbc/hb0/8834253127710/produkter.csv'
            $VinmonopoletRequest = Invoke-WebRequest -Uri $ProductsRawVinmonopoletUrl
            $VinmonopoletProducts = $VinmonopoletRequest.Content | ConvertFrom-Csv -Delimiter ';'
            Foreach ($Entry in $VinmonopoletProducts) {
                Write-Progress -Activity 'Working..' -Status 'Vinmonopolet' -PercentComplete ((($VinmonopoletProducts.IndexOf($Entry))/($VinmonopoletProducts.Count))*100)
                $Product = New-Object Product
                $Product.Source            = 'Vinmonopolet'
                $Product.ProductNumber     = $Entry.Varenummer
                $Product.Name              = $Entry.Varenavn
                $Product.Price             = $Entry.Pris.Replace(',','.')
                $Product.Volume            = (([int]$Entry.Volum)*10)
                $Product.PricePerLiter     = $Entry.LiterPris.Replace(',','.')
                $Product.Category          = $Entry.Varetype
                $Product.Container         = $Entry.Emballasjetype
                $Product.AlcoholPercentage = $Entry.Alkohol.TrimEnd('%').Replace(',','.')
                #$ProductArray += $Product
                Write-Output $Product
            }
            Write-Progress -Activity 'Working..' -Completed  
        }
        if($Source -contains 'Systembolaget') {
            $ProductsRawSystembolagetUrl = 'https://www.systembolaget.se/api/assortment/products/xml'
            $SystembolagetRequest = Invoke-WebRequest -Uri $ProductsRawSystembolagetUrl
            [xml]$SystembolagetProducts = $SystembolagetRequest.Content
            [System.Array]$SystembolagetProducts = $SystembolagetProducts.artiklar.artikel
            Foreach ($Entry in $SystembolagetProducts) {
                Write-Progress -Activity 'Working..' -Status 'Systembolaget' -PercentComplete ((($SystembolagetProducts.IndexOf($Entry))/($SystembolagetProducts.Count))*100)
                $Product = New-Object Product
                $Product.Source            = 'Systembolaget'
                $Product.Productnumber     = $Entry.Varnummer
                $Product.Name              = "$($Entry.Namn) $($Entry.Namn2)"
                $Product.Price             = $Entry.Prisinklmoms
                $Product.Volume            = ([int]$Entry.Volymiml)
                $Product.PricePerLiter     = $Entry.PrisPerLiter
                $Product.Category          = $Entry.Varugrupp
                $Product.Container         = $Entry.Forpackning
                $Product.AlcoholPercentage = $Entry.Alkoholhalt.TrimEnd('%')
                #$ProductArray += $ProductProps
                Write-Output $Product
            }
            Write-Progress -Activity 'Working..' -Completed
        }
    }
    End {
        #Write-Output $ProductArray
    }
}