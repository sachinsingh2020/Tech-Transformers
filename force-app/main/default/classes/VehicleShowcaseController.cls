public without sharing class VehicleShowcaseController {
    
    @AuraEnabled(cacheable=true)
    public static List<Vehicle> getVehicles() {
        try {
            return [
                SELECT Id, 
                       Name,
                       MakeName,
                       ModelName,
                       ModelYear,
                       TrimLevel,
                       ExteriorColor,
                       Status,
                       MarketPrice
                FROM Vehicle
                ORDER BY CreatedDate DESC
                LIMIT 100
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving vehicles: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String createTestDriveRequest(
        String vehicleId,
        String customerName,
        String customerEmail,
        String customerPhone,
        Date preferredDate,
        String comments
    ) {
        try {
            Task testDriveTask = new Task(
                WhatId = vehicleId,
                Subject = 'Test Drive Request - ' + customerName,
                Description = 'Customer Name: ' + customerName + '\n' +
                             'Email: ' + customerEmail + '\n' +
                             'Phone: ' + customerPhone + '\n' +
                             'Preferred Date: ' + preferredDate + '\n' +
                             'Comments: ' + comments,
                ActivityDate = preferredDate,
                Status = 'Not Started',
                Priority = 'High'
            );
            
            insert testDriveTask;
            
            sendTestDriveConfirmationEmail(customerEmail, customerName, preferredDate);
            
            return testDriveTask.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating test drive request: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String createPurchaseRequest(
        String vehicleId,
        String customerName,
        String customerEmail,
        String customerPhone,
        String comments
    ) {
        try {
            Vehicle vehicle = [
                SELECT Id, Name, MarketPrice
                FROM Vehicle
                WHERE Id = :vehicleId
                LIMIT 1
            ];
            
            Opportunity opp = new Opportunity(
                Name = 'Vehicle Purchase - ' + vehicle.Name,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                Amount = vehicle.MarketPrice,
                Description = 'Customer Name: ' + customerName + '\n' +
                             'Email: ' + customerEmail + '\n' +
                             'Phone: ' + customerPhone + '\n' +
                             'Comments: ' + comments,
                LeadSource = 'Website',
                Type = 'New Customer'
            );
            
            insert opp;
            
            sendPurchaseConfirmationEmail(opp, customerEmail, customerName);
            
            return opp.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating purchase request: ' + e.getMessage());
        }
    }
    
    private static void sendTestDriveConfirmationEmail(String email, String name, Date preferredDate) {
        try {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { email });
            mail.setSubject('Test Drive Request Confirmed');
            mail.setPlainTextBody(
                'Dear ' + name + ',\n\n' +
                'Thank you for your interest in test driving our vehicle. ' +
                'Your request has been received and our team will contact you shortly to confirm the details.\n\n' +
                'Preferred Date: ' + preferredDate + '\n\n' +
                'Best regards,\n' +
                'Vehicle Sales Team'
            );
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        } catch (Exception e) {
            System.debug('Error sending test drive confirmation email: ' + e.getMessage());
        }
    }
    
    private static void sendPurchaseConfirmationEmail(Opportunity opp, String email, String name) {
        try {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { email });
            mail.setSubject('Purchase Request Received');
            mail.setPlainTextBody(
                'Dear ' + name + ',\n\n' +
                'Thank you for your interest in purchasing a vehicle from us. ' +
                'Your purchase request has been received and our sales team will contact you shortly ' +
                'to discuss financing options, delivery details, and answer any questions you may have.\n\n' +
                'Best regards,\n' +
                'Vehicle Sales Team'
            );
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        } catch (Exception e) {
            System.debug('Error sending purchase confirmation email: ' + e.getMessage());
        }
    }
}