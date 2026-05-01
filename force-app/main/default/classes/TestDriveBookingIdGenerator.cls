public class TestDriveBookingIdGenerator {

    public class Input {
        @InvocableVariable(required=false)
        public String dummy;
    }

    public class Output {
        @InvocableVariable
        public String bookingId;
    }

    @InvocableMethod(label='Generate Unique Booking ID' description='Generates a unique 10 digit booking id starting with 7')
    public static List<Output> generateBookingId(List<Input> inputs) {

        List<Output> outputList = new List<Output>();

        Set<String> existingIds = getExistingBookingIds();

        for (Input inp : inputs) {
            Output out = new Output();
            out.bookingId = generateUniqueBookingId(existingIds);
            outputList.add(out);
        }

        return outputList;
    }

    private static String generateUniqueBookingId(Set<String> existingIds) {
        String bookingId;
        Integer maxAttempts = 10;
        Integer attempt = 0;

        do {
            bookingId = generateRandom10DigitStartingWith7();
            attempt++;
        } while (existingIds.contains(bookingId) && attempt < maxAttempts);

        if (existingIds.contains(bookingId)) {
            throw new AuraHandledException('Unable to generate unique Booking ID. Try again.');
        }

        return bookingId;
    }

    private static String generateRandom10DigitStartingWith7() {
        String bookingId = '7';

        for (Integer i = 0; i < 9; i++) {
            Integer digit = Math.mod(Math.abs(Crypto.getRandomInteger()), 10);
            bookingId += String.valueOf(digit);
        }

        return bookingId;
    }

    private static Set<String> getExistingBookingIds() {
        Set<String> bookingIds = new Set<String>();

        for (Test_Drive__c td : [
            SELECT Booking_Id__c
            FROM Test_Drive__c
            WHERE Booking_Id__c != NULL
        ]) {
            bookingIds.add(td.Booking_Id__c);
        }

        return bookingIds;
    }
}