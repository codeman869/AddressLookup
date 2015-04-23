# AddressLookup

**Description**


Ruby program to look up addresses in a CSV file and return Lat / Long. The program will loop through each address in the file and utilize Google Maps API to return the Lat / Long. The address as well as additional information is added to a new CSV file. A simple row counter is used to resume address lookup for a specific row. Google Maps API limits are set to 2500 requests per day. Request counting and automatic sleep functionality is built in to limit the application to "nice" behavior.
