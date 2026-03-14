# =========================
# EMAIL TEMPLATES
# =========================
# Onboarding email template functions.
# MSA template: QLD, NSW, TAS (and TEST)
# MSV template: VIC
# MSV mandatory training: VIC only (second email)
# Future: migrate to SharePoint List or HTML template files.

function New-MsaOnboardingEmailBody {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$FirstName,
    [Parameter(Mandatory)][string]$Upn,
    [Parameter(Mandatory)][string]$TempPassword,
    [Parameter(Mandatory)][string]$SenderName,
    [Parameter(Mandatory)][string]$SenderTitle
  )

@"
<html>
<body style="font-family: Calibri, Arial, sans-serif; font-size: 11pt;">

<p>Hi $FirstName,</p>

<p><strong>Welcome to the MSA Team!</strong> My name is $SenderName. I am an $SenderTitle servicing all MSA schools. There are just a few more things needed to get you started with us.</p>

<p><strong>Please see below your MSA email account which is accessible via Microsoft:</strong></p>

<p>
<a href="https://office.com/">Microsoft Account Access (https://office.com/)</a><br/>
<br/>
<strong>Username:</strong> $Upn<br/>
<strong>Password:</strong> $TempPassword
</p>

<p>If you have any issues accessing your MSA email account, please let me know. Any future emails from IT or the school will come to your MSA email.</p>

<hr/>

<p><strong>Cyber Security Training</strong></p>

<p>On your first day, you will be issued Cyber Security training as part of your employment at MSA. This training is compulsory for all staff and must be completed within the allocated time frame of three weeks. New training programs are issued three times per term and this will be for the entirety of your employment. Ensuring staff are equipped with the skills necessary to identify criminal cyber activity is paramount to the protection of MSA.</p>

<hr/>

<p><strong>Connecting with MSA</strong></p>

<p>With this onboarding email comes access to our IT Help Platform, hosted by Freshworks, that will give you all the basics of connecting to our wireless network, printers and other services. Firstly, you'll need to <a href="https://service.msa.qld.edu.au/support/solutions/articles/75000121803">follow this guide</a> to sign into the Freshworks system utilising your Microsoft account details. Once logged in, you'll be able to see our primary portal offering you various services such as lodging help tickets for support, browsing our support articles or making requests for computers or tools. We highly recommend perusing the following articles to ensure you can access systems as expected on your first day.</p>

<p>Our recommended reading can all <a href="https://service.msa.qld.edu.au/support/solutions/75000028330">be found at this link</a>, but our recommended reading articles are:</p>

<ul>
<li><a href="https://service.msa.qld.edu.au/support/solutions/articles/75000118671">How to Connect to MSA WiFi Networks</a></li>
<li><a href="https://service.msa.qld.edu.au/support/solutions/articles/75000111898">Logging into MSA Computers</a></li>
<li><a href="https://service.msa.qld.edu.au/support/solutions/articles/75000092029">Logging IT Service Tickets</a></li>
<li><a href="https://service.msa.qld.edu.au/support/solutions/articles/75000121602">How to Login to Compass</a></li>
<li><a href="https://service.msa.qld.edu.au/support/solutions/articles/75000082216">How to Get Microsoft Office</a></li>
<li><a href="https://service.msa.qld.edu.au/support/solutions/articles/75000108846">MSA Email Groups</a></li>
<li><a href="https://service.msa.qld.edu.au/support/solutions/articles/75000120006">Phone Line Extensions</a></li>
</ul>

<p>If you have any questions, please do not hesitate to email <a href="mailto:ITService@msa.qld.edu.au">ITService@msa.qld.edu.au</a> to submit a ticket and receive support from our team.</p>

</body>
</html>
"@
}

function New-MsvOnboardingEmailBody {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$FirstName,
    [Parameter(Mandatory)][string]$Upn,
    [Parameter(Mandatory)][string]$TempPassword,
    [Parameter(Mandatory)][string]$SenderName,
    [Parameter(Mandatory)][string]$SenderTitle
  )

@"
<html>
<body style="font-family: Calibri, Arial, sans-serif; font-size: 11pt;">

<p>Hi $FirstName,</p>

<p><strong>Welcome to the MSV Team!</strong> My name is $SenderName. I am an $SenderTitle servicing all MSV schools. There are just a few more things needed to get you started with us.</p>

<p><strong>Please see below your MSV email account which is accessible via Microsoft:</strong></p>

<p>
<a href="https://office.com/">Microsoft Account Access (https://office.com/)</a><br/>
<br/>
<strong>Username:</strong> $Upn<br/>
<strong>Password:</strong> $TempPassword
</p>

<p>If you have any issues accessing your MSV email account, please let me know. Any future emails from IT or the school will come to your MSV email.</p>

<hr/>

<p><strong>Cyber Security Training</strong></p>

<p>On your first day, you will be issued Cyber Security training as part of your employment at MSV. This training is compulsory for all staff and must be completed within the allocated time frame of three weeks. New training programs are issued three times per term and this will be for the entirety of your employment. Ensuring staff are equipped with the skills necessary to identify criminal cyber activity is paramount to the protection of MSV.</p>

<hr/>

<p><strong>Connecting with MSV</strong></p>

<p>With this onboarding email comes access to our IT Help Platform, hosted by Freshworks, that will give you all the basics of connecting to our wireless network, printers and other services. Firstly, you'll need to <a href="https://service.msa.qld.edu.au/support/solutions/articles/75000121803">follow this guide</a> to sign into the Freshworks system utilising your Microsoft account details. Once logged in, you'll be able to see our primary portal offering you various services such as lodging help tickets for support, browsing our support articles or making requests for computers or tools. We highly recommend perusing the following articles to ensure you can access systems as expected on your first day.</p>

<p>Our recommended reading can all <a href="https://service.msa.qld.edu.au/support/solutions/75000028330">be found at this link</a>, but our recommended reading articles are:</p>

<ul>
<li><a href="https://service.msa.qld.edu.au/support/solutions/articles/75000118671">How to Connect to MSV WiFi Networks</a></li>
<li><a href="https://service.msa.qld.edu.au/support/solutions/articles/75000111898">Logging into MSV Computers</a></li>
<li><a href="https://service.msa.qld.edu.au/support/solutions/articles/75000092029">Logging IT Service Tickets</a></li>
<li><a href="https://service.msa.qld.edu.au/support/solutions/articles/75000121602">How to Login to Compass</a></li>
<li><a href="https://service.msa.qld.edu.au/support/solutions/articles/75000082216">How to Get Microsoft Office</a></li>
<li><a href="https://service.msa.qld.edu.au/support/solutions/articles/75000108846">MSV Email Groups</a></li>
<li><a href="https://service.msa.qld.edu.au/support/solutions/articles/75000120006">Phone Line Extensions</a></li>
</ul>

<p>If you have any questions, please do not hesitate to email <a href="mailto:ITService@msa.qld.edu.au">ITService@msa.qld.edu.au</a> to submit a ticket and receive support from our team.</p>

</body>
</html>
"@
}

function New-MsvMandatoryTrainingEmailBody {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$FirstName,
    [Parameter(Mandatory)][string]$SenderName,
    [Parameter(Mandatory)][string]$SenderTitle
  )

@"
<html>
<body style="font-family: Calibri, Arial, sans-serif; font-size: 11pt;">

<p>Hi $FirstName,</p>

<p>As part of your onboarding with MSV, you are required to complete the following mandatory training modules. Please complete both courses and send your certificates as instructed below.</p>

<hr/>

<p><strong>Child Protection</strong> (approx. 30 minutes to complete)</p>

<p>Please note, I would recommend you read school policies on child protection/mandatory reporting so you can breeze through the course.</p>

<ol>
<li>Click on this link to access the online training portal for Non-Government schools: <a href="https://training.infosharing.vic.gov.au">https://training.infosharing.vic.gov.au</a></li>
<li>Create your account by completing all sections displayed
  <ul>
  <li>In the <strong>Role</strong> section, Assistant Teachers and Support Workers should select <em>Teacher's Aid and Education Support</em>. Everyone else is obvious.</li>
  <li>In the <strong>About Your Organisation</strong> section, under Service Type select <em>Independent School</em> and under Organisation Type select <em>not-for-profit organisation</em>.</li>
  <li>We don't have a Service Number so you can skip this section.</li>
  </ul>
</li>
<li>Confirm your email address</li>
<li>Agree to the terms and policies</li>
<li>Select the <strong>Protecting Children</strong> tile and select <em>Protecting Children - Mandatory Reporting and Other Obligations Non-Government Schools</em> course</li>
<li>On the information page, under <strong>Learning Module</strong> click the hyperlink to <em>Mandatory Reporting and Other Obligations</em> and this will take you to the e-learning training</li>
<li>Complete all sections and quizzes within the module. Please note, you must click on everything within each module for it to register as complete. Skipping through doesn't work.</li>
<li>You'll then have an assessment to complete when you return to the information page under <strong>Assessment</strong></li>
<li>Once complete, follow the step that will take you back to the course information page where you can download a copy of your certificate</li>
<li>Save as PDF, <strong>change file name to &lt;FULL NAME Protecting Children Certificate $(Get-Date -Format 'yyyy')&gt;</strong></li>
<li>Send this to <a href="mailto:bundoora@msv.vic.edu.au">bundoora@msv.vic.edu.au</a> for record keeping</li>
</ol>

<hr/>

<p><strong>Information Sharing for Education Workforces</strong> (approx. 30 minutes to complete)</p>

<ol>
<li>Click on this link to access the online training portal for Non-Government schools: <a href="https://training.infosharing.vic.gov.au">https://training.infosharing.vic.gov.au</a></li>
<li>Select the <strong>Education Workforces</strong> tile then select the <em>Information Sharing for Education Workforces</em> course</li>
<li>On the information page, under the <strong>eLearn Modules</strong> section, there will be <strong>4 modules</strong> for you to complete. Click on Module 1 to start and follow the instructions within. Please note, you must click on everything within each module for it to register as complete. Skipping through doesn't work.</li>
<li>Please complete all 4 modules. There are mini quizzes within each but no end of course assessment.</li>
<li>Once complete, follow the step that will take you back to the course information page where you can download a copy of your certificate</li>
<li>Save as PDF, <strong>change file name to &lt;FULL NAME Information Sharing Certificate $(Get-Date -Format 'yyyy')&gt;</strong></li>
<li>Send this to <a href="mailto:bundoora@msv.vic.edu.au">bundoora@msv.vic.edu.au</a> for record keeping</li>
</ol>

<p>If you have any questions, please do not hesitate to email <a href="mailto:ITService@msa.qld.edu.au">ITService@msa.qld.edu.au</a> to submit a ticket and receive support from our team.</p>

</body>
</html>
"@
}
