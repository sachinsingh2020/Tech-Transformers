public with sharing class SendTestDriveConfirmationEmail {

    public class Input {
        @InvocableVariable(required=true)
        public Test_Drive__c testDrive;

        @InvocableVariable(required=true)
        public ServiceAppointment serviceAppointment;

        @InvocableVariable(required=true)
        public Contact contact;
    }

    public class Output {
        @InvocableVariable
        public Boolean isSent;

        @InvocableVariable
        public String message;
    }

    @InvocableMethod(label='Send Test Drive Confirmation Email')
    public static List<Output> sendEmail(List<Input> inputs) {

        List<Output> results = new List<Output>();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        Id oweaId;
        List<OrgWideEmailAddress> oweaList = [
            SELECT Id FROM OrgWideEmailAddress 
            WHERE Address = 'aakanshak@astreait.com' 
            LIMIT 1
        ];
        if (!oweaList.isEmpty()) {
            oweaId = oweaList[0].Id;
        }

        Set<Id> parentIds = new Set<Id>();
        for (Input req : inputs) {
            if (req.serviceAppointment != null && req.serviceAppointment.ParentRecordId != null) {
                parentIds.add(req.serviceAppointment.ParentRecordId);
            }
        }

        Map<Id, Account> accountMap = new Map<Id, Account>();
        if (!parentIds.isEmpty()) {
            accountMap = new Map<Id, Account>(
                [SELECT Id, Name, Phone FROM Account WHERE Id IN :parentIds]
            );
        }

        for (Input req : inputs) {

            Output res = new Output();

            try {
                String email = req.contact.Email;

                if (String.isBlank(email)) {
                    res.isSent = false;
                    res.message = 'Email is blank';
                    results.add(res);
                    continue;
                }

                String customerName = req.contact.Name;
                String phone = req.contact.Phone;

                String vehicleModel = String.valueOf(req.testDrive.Model_Interested__c);
                String bookingId = String.valueOf(req.testDrive.Booking_Id__c);
                String appointmentType = String.valueOf(req.serviceAppointment.AppointmentType);

                String location =
                    (req.serviceAppointment.Street != null ? req.serviceAppointment.Street + ', ' : '') +
                    (req.serviceAppointment.City != null ? req.serviceAppointment.City + ', ' : '') +
                    (req.serviceAppointment.State != null ? req.serviceAppointment.State + ', ' : '') +
                    (req.serviceAppointment.PostalCode != null ? req.serviceAppointment.PostalCode + ', ' : '') +
                    (req.serviceAppointment.Country != null ? req.serviceAppointment.Country : '');

                String dealerName = '';
                String dealerPhone = '';

                Id parentId = req.serviceAppointment.ParentRecordId;

                if (parentId != null && accountMap.containsKey(parentId)) {
                    Account dealerAcc = accountMap.get(parentId);
                    dealerName = dealerAcc.Name;
                    dealerPhone = dealerAcc.Phone != null ? dealerAcc.Phone : 'Not Available';
                }

                String appointmentDateTime = '';
                if (req.serviceAppointment.SchedStartTime != null) {
                    appointmentDateTime = req.serviceAppointment.SchedStartTime.format('dd MMM yyyy, hh:mm a');
                }

                String htmlBody = ''
                + '<div style="font-family: Arial, sans-serif; padding: 20px; background-color: #f4f6f8;">'
                + '  <div style="max-width: 600px; margin: auto; background: #ffffff; border-radius: 10px;">'

                + '    <div style="background: #2a5298; color: white; padding: 20px; text-align: center;">'
                + '      <h1>Tech Transformers</h1>'
                + '      <p>Test Drive Confirmation</p>'
                + '    </div>'

                + '    <div style="padding: 20px;">'
                + '      <h3>Hello ' + customerName + ',</h3>'
                + '      <p>Your test drive has been successfully booked. Here are the details:</p>'

                + '      <table style="width:100%; border-collapse: collapse;">'
                + '        <tr><td><b>Vehicle Model</b></td><td>' + vehicleModel + '</td></tr>'
                + '        <tr><td><b>Booking ID</b></td><td>' + bookingId + '</td></tr>'
                + '        <tr><td><b>Date & Time</b></td><td>' + appointmentDateTime + '</td></tr>'
                + '        <tr><td><b>Location</b></td><td>' + location + '</td></tr>'
                + '        <tr><td><b>Dealer</b></td><td>' + dealerName + '</td></tr>'
                + '        <tr><td><b>Dealer Phone</b></td><td><a href="tel:' + dealerPhone + '">' + dealerPhone + '</a></td></tr>'
                + '        <tr><td><b>Your Phone</b></td><td>' + phone + '</td></tr>'
                + '        <tr><td><b>Appointment Type</b></td><td>' + appointmentType + '</td></tr>'
                + '      </table>'

                + '      <p style="margin-top:20px;">We look forward to your visit 🚗</p>'
                + '      <p>Regards,<br/><b>Tech Transformers Team</b></p>'
                + '    </div>'

                + '  </div>'
                + '</div>';

                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new List<String>{ email });
                mail.setSubject('🚗 Your Test Drive is Confirmed!');
                mail.setHtmlBody(htmlBody);

                if (oweaId != null) {
                    mail.setOrgWideEmailAddressId(oweaId);
                }

                emails.add(mail);

                res.isSent = true;
                res.message = 'Queued';

            } catch (Exception e) {
                res.isSent = false;
                res.message = e.getMessage();
            }

            results.add(res);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }

        return results;
    }
}