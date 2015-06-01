require  "nokogiri"
require 'health-data-standards'

# bundle update
# bundle exec ruby patid_detector.rb 
module HealthDataStandards
  module Import
    module Cat1
        # INPUT a list of QRDA1 files 
        # OUTPUT a list of Cypress medical record numbers
        
        class PatientFromQRDA
            attr_accessor :fileName, :encounters, :conditions, :insurances, :procedures
            
            def initialize(fileName)
                @fileName=fileName
                @encounters=[]
                @conditions=[]
                @insurances=[]
                @procedures=[]
            end
            
        end
        
        class CypressMedicalNumberRetriver
            attr_accessor :qrda1Folder, :mongoParametersFile
            #constructor taking the location of the QRDA1 files to explore 
            #and a file containing MongoDB connection parameters
            def initialize (qrda1Folder,mongoParametersFile)
                @qrda1Folder=qrda1Folder
                @mongoParametersFile=mongoParametersFile
            end
            
            
            #a method that goues through the directory containing the QRDA files and loads them into an array of PatientFromQRDA 
            def loadQRDAFiles()
                #method that goues through the directory containing the QRDA files and loads them into an array of PatientFromQRDA 
                patientsFromQRDAs = Array.new
                Dir.glob("#{@qrda1Folder}/*.xml") do |qrdaFile|
                    puts "\nloading on:::: #{qrdaFile}"
                    patientFromQRDA = PatientFromQRDA.new(qrdaFile)
                    
                    doc = Nokogiri::XML(File.new(qrdaFile))
                    doc.root.add_namespace_definition('cda', 'urn:hl7-org:v3')
                    doc.root.add_namespace_definition('sdtc', 'urn:hl7-org:sdtc')
                    patient_data = Cat1::PatientImporter.instance.parse_cat1(doc)
                    patient = Record.update_or_create(patient_data)
                    
                    
                    for encounter in patient.encounters
                        puts "encounter: #{encounter.codes}"
                        patientFromQRDA.encounters << encounter.codes
                    end
                    for condition in patient.conditions
                        puts "condition: #{condition.codes}"
                        patientFromQRDA.conditions << condition.codes
                    end
                    for ip in patient.insurance_providers
                        puts "insurance: #{ip.codes}"
                        patientFromQRDA.insurances << ip.codes
                    end
                    for procedure in  patient.procedures
                        puts "procedure: #{procedure.codes['LOINC']}"
                        puts "procedure: #{procedure.codes}"
                        patientFromQRDA.procedures << procedure.codes
                    end
                    # encounter = patient.encounters.first
                    # puts "#{encounter.codes}"
                    # puts patient_data.test_condition_expired
                    # record = Record.update_or_create(patient_data)
                    # puts patient_data.medical_record_number
                    # puts "\n\n#{patient_data.encounters}"
                    
                    # record = Record.update_or_create(patient_data)
                    patientsFromQRDAs << patientFromQRDA
                    
                end
                puts "encounters  collected for first "+patientsFromQRDAs.first.encounters.length.to_s
                puts "procedures  collected for first "+patientsFromQRDAs.first.procedures.length.to_s 
                puts "conditions  collected for first "+patientsFromQRDAs.first.conditions.length.to_s 
                # the QRDA patients are loaded into patientsFromQRDAs
                # go against a Cypress mongoDb and collect patients (they are stored in records collection) that are similar with the ones collected from QRDA files - a QRDA patinet is equivalent with one from Cypress db if encounters+conditions (Diagnosis)+insurance_providers+procedures are similar
                
                # session = Moped::Session.new([ "54.152.244.137:27017" ])
                # session.use "cypress_development"
                # session[:records].find(first:"Randy")
                Mongoid.load!("mongoid.yml", :production)
                puts "#{Mongoid.default_session.collections}"
                
                # db = Mongoid::Sessions.default
                # found = Record.where(:birthdate.gte => 0)
                # Record.each do |record|
                #     puts "#{record}"
                # end
                # existing = Record.where(first:"Randy").first
                # puts ":::"+ existing.to_s
                # puts found.length.to_s
                
                # mongo_client=nil
                # mongo_client = MongoClient.new("54.152.244.137", 27017)
                # puts mongo_client.database_names 
                # client  = MongoClient.new("54.152.244.137", 27017)
                # db   = client.db('cypress_development')
                puts "After mongo"
                
            end
            
            
            
            #lists xml files in a directory     
            def listFiles()
                puts "got here"
                puts "QRDA1 folder: #@qrda1Folder"
                puts "MongoDB parameters: #@mongoParametersFile"
                Dir.glob("#{@qrda1Folder}/*.xml") do |my_text_file|
                    puts "working on: #{my_text_file}"
                end
            end
        end
        puts "starts"
        #initialize mongo
        Mongoid.load!("mongoid.yml", :development)
        retriever = CypressMedicalNumberRetriver.new("/home/ubuntu/workspace/data/_tmp", "/home/ubuntu/workspace/data/remoteMongo/remoteMongo.properties")
        # retriever.listFiles()
        retriever.loadQRDAFiles()
        puts "ends"
    end
  end
end