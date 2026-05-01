public with sharing class VehicleSearchService {

    public class Input {
        @InvocableVariable(label='Battery Type')
        public String batteryType;

        @InvocableVariable(label='Body Type')
        public String bodyType;

        @InvocableVariable(label='Door Count')
        public Integer doorCount;

        @InvocableVariable(label='Engine Capacity')
        public String engineCapacity; 

        @InvocableVariable(label='Random Vehicles')
        public Boolean getAllRecords;
    }

    public class Output {
        @InvocableVariable(label='Vehicle Id')
        public Id vehicleId;

        @InvocableVariable(label='Vehicle Name')
        public String vehicleName;

        @InvocableVariable(label='Vehicle Definition Id')
        public Id vehicleDefinitionId;

        @InvocableVariable(label='Exterior Color')
        public String exteriorColor;

        @InvocableVariable(label='Interior Color')
        public String interiorColor;
    }

    @InvocableMethod(label='Search Vehicles Based on Filters')
    public static List<List<Output>> searchVehicles(List<Input> inputs) {

        if (inputs == null || inputs.isEmpty()) {
            return new List<List<Output>>();
        }

        Input input = inputs[0];

        String batteryType = input.batteryType;
        String bodyType = input.bodyType;
        Integer doorCount = input.doorCount;
        String engineCapacity = input.engineCapacity;

        String query = 'SELECT Id FROM VehicleDefinition WHERE Id != null';

        if (input.getAllRecords == null || input.getAllRecords == false) {

            if (!String.isBlank(batteryType)) {
                query += ' AND MainBatteryType = :batteryType';
            }

            if (!String.isBlank(bodyType)) {
                query += ' AND BodyType = :bodyType';
            }

            if (doorCount != null) {
                query += ' AND DoorCount = :doorCount';
            }

            if (!String.isBlank(engineCapacity)) {
                query += ' AND EngineCubicCapacity = :engineCapacity'; 
            }
        }

        List<VehicleDefinition> definitions = Database.query(query);

        if (definitions.isEmpty()) {
            return new List<List<Output>>();
        }

        Set<Id> defIds = new Set<Id>();
        for (VehicleDefinition vd : definitions) {
            defIds.add(vd.Id);
        }

        List<Vehicle> vehicles = [
            SELECT Id, Name, VehicleDefinitionId,
                   ExteriorColor, InteriorColor
            FROM Vehicle
            WHERE VehicleDefinitionId IN :defIds
            LIMIT 100
        ];

        List<Output> results = new List<Output>();

        for (Vehicle v : vehicles) {
            Output o = new Output();
            o.vehicleId = v.Id;
            o.vehicleName = v.Name;
            o.vehicleDefinitionId = v.VehicleDefinitionId;
            o.exteriorColor = v.ExteriorColor;
            o.interiorColor = v.InteriorColor;
            results.add(o);
        }
		
        List<List<Output>> finalResult = new List<List<Output>>();
        finalResult.add(results);
        return finalResult;
    }
}