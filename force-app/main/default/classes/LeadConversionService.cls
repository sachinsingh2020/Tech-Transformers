public class LeadConversionService {

    public class Input {
        @InvocableVariable(required=true)
        public Id leadId;
    }

    public class Output {
        @InvocableVariable
        public Id accountId;

        @InvocableVariable
        public Id contactId;

        @InvocableVariable
        public String message;
    }

    @InvocableMethod(label='Convert Lead with Matching Logic')
    public static List<Output> convertLeads(List<Input> inputs) {

        List<Output> results = new List<Output>();

        List<LeadStatus> statuses = [
            SELECT MasterLabel 
            FROM LeadStatus 
            WHERE IsConverted = true
        ];

        String finalStatus;
        for (LeadStatus ls : statuses) {
            if (ls.MasterLabel == 'Converted') {
                finalStatus = ls.MasterLabel;
                break;
            }
        }
        if (finalStatus == null && !statuses.isEmpty()) {
            finalStatus = statuses[0].MasterLabel;
        }

        for (Input input : inputs) {

            Output res = new Output();

            try {

                Lead leadRec = [
                    SELECT Id, Email, FirstName, LastName, Company, IsConverted
                    FROM Lead
                    WHERE Id = :input.leadId
                    LIMIT 1
                ];

                if (leadRec.IsConverted) {
                    res.message = 'Lead already converted';
                    results.add(res);
                    continue;
                }

                Contact existingContact = null;
                List<Contact> contacts = [
                    SELECT Id, AccountId
                    FROM Contact
                    WHERE Email = :leadRec.Email
                    LIMIT 1
                ];
                if (!contacts.isEmpty()) {
                    existingContact = contacts[0];
                }

                Account existingPA = null;
                List<Account> accounts = [
                    SELECT Id, PersonContactId
                    FROM Account
                    WHERE PersonEmail = :leadRec.Email
                    AND IsPersonAccount = true
                    LIMIT 1
                ];
                if (!accounts.isEmpty()) {
                    existingPA = accounts[0];
                }

                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(leadRec.Id);
                lc.setDoNotCreateOpportunity(true);
                lc.setConvertedStatus(finalStatus);

                if (existingContact != null) {
                    lc.setContactId(existingContact.Id);
                    lc.setAccountId(existingContact.AccountId);
                } 
                else if (existingPA != null) {
                    lc.setAccountId(existingPA.Id);
                    lc.setContactId(existingPA.PersonContactId);
                }

                Database.LeadConvertResult lcr = Database.convertLead(lc);

                if (lcr.isSuccess()) {
                    res.accountId = lcr.getAccountId();
                    res.contactId = lcr.getContactId();
                    res.message = 'Lead converted successfully';
                } else {
                    res.message = 'Conversion failed';
                }

            } catch (Exception e) {
                res.message = 'Error: ' + e.getMessage();
            }

            results.add(res);
        }

        return results;
    }
}