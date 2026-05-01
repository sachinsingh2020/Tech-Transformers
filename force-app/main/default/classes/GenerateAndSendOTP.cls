public with sharing class GenerateAndSendOTP {

    public class Input {
        @InvocableVariable(required=true)
        public String email;
    }

    public class Output {
        @InvocableVariable
        public Boolean isSent;

        @InvocableVariable
        public String otp; 
    }

    @InvocableMethod(label='Generate and Send OTP')
    public static List<Output> generateOTP(List<Input> inputs) {

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        List<Output> results = new List<Output>();

        for (Input req : inputs) {

            Output res = new Output();
            res.isSent = false;
            res.otp = null;

            if (String.isBlank(req.email)) {
                results.add(res);
                continue;
            }

            Integer otpVal = Math.mod(Math.abs(Crypto.getRandomInteger()), 900000) + 100000;
            String otpStr = String.valueOf(otpVal);

            res.otp = otpStr;

            String emailBody =
            '<html>' +
            '<body style="font-family: Arial, sans-serif; background-color: #f4f6f9; padding: 20px;">' +
            '<div style="max-width: 600px; margin: auto; background: #ffffff; border-radius: 10px; padding: 20px;">' +

            '<h2 style="color: #e74c3c; text-align: center;">❌ Cancel Booking Verification</h2>' +

            '<p style="font-size: 16px; color: #333;">Hello 👋,</p>' +

            '<p style="font-size: 15px; color: #555;">We received a request to cancel your booking appointment.</p>' +

            '<p style="font-size: 15px; color: #555;">Please use the OTP below to confirm your cancellation:</p>' +

            '<div style="text-align: center; margin: 25px 0;">' +
            '<span style="font-size: 28px; letter-spacing: 5px; font-weight: bold; color: #ffffff; background: #e74c3c; padding: 12px 25px; border-radius: 8px;">' +
            otpStr +
            '</span>' +
            '</div>' +

            '<p style="font-size: 14px; color: #777;">If you did not request this cancellation, please ignore this email.</p>' +
            '<p style="font-size: 14px; color: #777;">Do not share this OTP with anyone.</p>' +

            '</div></body></html>';

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            List<OrgWideEmailAddress> oweaList = [
                SELECT Id FROM OrgWideEmailAddress 
                WHERE Address = 'aakanshak@astreait.com' 
                LIMIT 1
            ];

            if (!oweaList.isEmpty()) {
                mail.setOrgWideEmailAddressId(oweaList[0].Id);
            }

            mail.setToAddresses(new List<String>{req.email});
            mail.setSubject('Cancel Booking OTP Verification');
            mail.setHtmlBody(emailBody);

            emails.add(mail);

            res.isSent = true;
            results.add(res);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }

        return results;
    }
}