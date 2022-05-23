*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Robocorp.Vault
Library           RPA.Browser.Selenium    
Library           RPA.Excel.Files
Library           RPA.HTTP
Library           RPA.PDF
Library           RPA.Tables
Library           RPA.Archive
Library           RPA.FileSystem
Library             RPA.Dialogs
Library    Process

*** Variables ***
${PDF_TEMP_OUTPUT_DIRECTORY}=       ${OUTPUT_DIR}${/}temp
${GLOBAL_RETRY_AMOUNT}=         3x
${GLOBAL_RETRY_INTERVAL}=       1s

*** Tasks ***
Order the robotos
     Open the Browser
     Download the Excel file
     Order robots from RobotSpareBin Industries Inc
     Create ZIP Package from PDF Files
***Keywords***
Set up directories
    Create Directory    ${PDF_TEMP_OUTPUT_DIRECTORY}
   
Open the Browser    
         ${secret}=    Get Secret    ProjectURL
         Open Available Browser    ${secret}[URL]
         #Open Available Browser    https://robotsparebinindustries.com/#/robot-order
         Click Button    OK
Download the Excel file    
        ${excel_file_path}=    Collect CSV file Link from the user     
        Download    ${excel_file_path}    overwrite=True
        #Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
Order robots from RobotSpareBin Industries Inc
    ${orders}=
    ...    Read Table From Csv
    ...    ${CURDIR}${/}orders.csv
    ...    header=True
    Log    ${orders}
    Close Workbook
    FOR    ${i}    IN    @{orders}
        Fill and order individual robot    ${i}
        ${c} =   Get Element Count   id:order-another
        IF    ${c} >= 1
            Click Button    Order another robot
            Click Button    OK  
        END   
    END

Fill and order individual robot
    [Arguments]    ${i}
    Select From List By Value    id:head    ${i}[Head]
    Select Radio Button   body    id-body-1
    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${i}[Legs]
    Input Text    address     ${i}[Address]
    #Click Button    Preview
    Wait Until Keyword Succeeds    5x    1s    Preview the robot
    Wait Until Keyword Succeeds    5x    1s    Click the robot
    #Click Button    Order
    #Wait Until Element Is Visible    id:robot-preview-image
    #Wait Until Keyword Succeeds
    # ...    ${GLOBAL_RETRY_AMOUNT}
    #...    ${GLOBAL_RETRY_INTERVAL}
    #...    Wait Until Element Is Visible    id:robot-preview-image

    #Click Button    Order
    TRY
          ${c} =   Get Element Count   id:receipt
          IF    ${c} >= 1
             ${pdf}=   Store the receipt as a PDF file    ${i}[Order number]
             ${screenshot}=    Take a screenshot of the robot    ${i}[Order number]
             Embed the robot screenshot to the receipt PDF file    ${i}[Order number]    ${screenshot}    ${pdf}
        END
    EXCEPT  message
         Log    EXCEPT with no arguments catches any exception.
   
    END
   
Preview the robot
    Click Button   Preview
    #Wait Until Element Is Visible    id:robot-preview-image
Click the robot
    Click Button    Order
    Wait Until Element Is Visible    id:receipt
Store the receipt as a PDF file 
    [Arguments]    ${i}
    TRY
        ${c} =   Get Element Count   id:receipt
        #Wait Until Element Is Visible    id:receipt
        
        IF    ${c} >= 1
           ${Robots_receipt}=    Get Element Attribute    id:receipt    outerHTML
           Html To Pdf    ${Robots_receipt}    ${OUTPUT_DIR}${/}temp${/}receipt${i}.pdf
        END 
            
    EXCEPT  message
        Log    EXCEPT with no arguments catches any exception.
    FINALLY
        Log    EXCEPT with no arguments catches any exception.   
    END
    
    
Take a screenshot of the robot
    [Arguments]    ${i}
    TRY
        
        Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}OrdersScreenshot${i}.png   
    EXCEPT  message
        Log    EXCEPT with no arguments catches any exception.
           
    END
Embed the robot screenshot to the receipt PDF file    
    [Arguments]     ${i}    ${screenshot}    ${pdf}
    TRY   
        ${files}=    Create List
    ...    ${OUTPUT_DIR}${/}temp${/}receipt${i}.pdf
    ...    ${OUTPUT_DIR}${/}OrdersScreenshot${i}.png
        
        #Open Pdf    ${OUTPUT_DIR}${/}temp${/}receipt${i}.pdf
        Add Files To Pdf    ${files}    ${OUTPUT_DIR}${/}temp${/}receipt${i}.pdf
        #Close Pdf    ${OUTPUT_DIR}${/}temp${/}receipt${i}.pdf
   
    EXCEPT  
        Log    EXCEPT with no arguments catches any exception.
    END
Create ZIP Package from PDF Files

    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}${/}temp${/}
    ...    ${zip_file_name}
Collect CSV file Link from the user
   
    Add heading       Enter the URL
    Add text input    URL
    ...    label=Enter URL
    ...    placeholder=Enter URL here
    ...    rows=1
    ${result}=    Run dialog
    RETURN    ${result.URL} 


    