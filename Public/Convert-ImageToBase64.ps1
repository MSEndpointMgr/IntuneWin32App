function Convert-ImageToBase64 {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ImagePath
    )

    # Check if the file exists
    if (-Not (Test-Path $ImagePath)) {
        Write-Error "File not found: $ImagePath"
        return
    }

    # Get the file extension
    $extension = [System.IO.Path]::GetExtension($ImagePath).ToLower()

    # Check if the file extension is valid
    if ($extension -notin '.png', '.jpg', '.jpeg') {
        Write-Error "Invalid file type: $extension. Only PNG, JPG, and JPEG are supported."
        return
    }

    # Read the image file as a byte array
    $imageBytes = [System.IO.File]::ReadAllBytes($ImagePath)

    # Convert the byte array to a Base64 string
    $base64String = [System.Convert]::ToBase64String($imageBytes)

    # Output the Base64 string
    return $base64String
}