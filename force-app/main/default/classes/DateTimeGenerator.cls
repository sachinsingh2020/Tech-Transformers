public class DateTimeGenerator {

    public class Request {
        @InvocableVariable(label='Input')
        public String dummyInput;
    }

    public class Response {
        @InvocableVariable(label='Available Slots')
        public List<String> availableSlots;
    }

    @InvocableMethod(label='Get Available Time Slots')
    public static List<Response> generateAvailableSlots(List<Request> requests) {

        List<String> result = new List<String>();
        Set<String> bookedSlotKeys = new Set<String>();

        Date startDate = Date.today().addDays(1);
        Date endDate = startDate.addDays(10);

        DateTime startDateTime = DateTime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));
        DateTime endDateTime = DateTime.newInstance(endDate, Time.newInstance(23, 59, 59, 0));

        for (ServiceAppointment sa : [
            SELECT SchedStartTime 
            FROM ServiceAppointment 
            WHERE SchedStartTime >= :startDateTime 
            AND SchedStartTime <= :endDateTime
            AND Status != 'Canceled'
        ]) {
            if (sa.SchedStartTime != null) {
                String key = sa.SchedStartTime.format('yyyy-MM-dd HH');
                bookedSlotKeys.add(key);
            }
        }

        System.debug('Booked Slots (hour-level): ' + bookedSlotKeys.size());

        for (Date d = startDate; d <= endDate; d = d.addDays(1)) {

            Integer dayOfWeek = d.toStartOfWeek().daysBetween(d) + 1;

            if (dayOfWeek == 1 || dayOfWeek == 7) {
                continue;
            }

            for (Integer hour = 9; hour <= 17; hour++) {

                DateTime slot = DateTime.newInstance(d, Time.newInstance(hour, 0, 0, 0));
                String slotKey = slot.format('yyyy-MM-dd HH');

                if (bookedSlotKeys.contains(slotKey)) {
                    continue;
                }

                String formatted = slot.format('dd/MM/yyyy, h:mm a');
                result.add(formatted);
            }
        }

        System.debug('Final Available Slots: ' + result.size());

        Response res = new Response();
        res.availableSlots = result;

        return new List<Response>{ res };
    }
}