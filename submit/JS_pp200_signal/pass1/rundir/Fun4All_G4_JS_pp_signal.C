#ifndef MACRO_FUN4ALLG4JSPPSIGNAL_C
#define MACRO_FUN4ALLG4JSPPSIGNAL_C

#include <GlobalVariables.C>

#include <G4Setup_sPHENIX.C>
#include <G4_Bbc.C>
#include <G4_Global.C>
#include <G4_Input.C>
#include <G4_Production.C>
#include <G4_TrkrSimulation.C>

#include <phpythia8/PHPy8JetTrigger.h>

#include <ffamodules/FlagHandler.h>
#include <ffamodules/HeadReco.h>
#include <ffamodules/SyncReco.h>
#include <ffamodules/CDBInterface.h>

#include <fun4all/Fun4AllDstOutputManager.h>
#include <fun4all/Fun4AllOutputManager.h>
#include <fun4all/Fun4AllServer.h>
#include <fun4all/Fun4AllSyncManager.h>
#include <fun4all/Fun4AllUtils.h>

#include <phool/PHRandomSeed.h>
#include <phool/recoConsts.h>

#include <stdlib.h>

R__LOAD_LIBRARY(libfun4all.so)
R__LOAD_LIBRARY(libffamodules.so)

int Fun4All_G4_JS_pp_signal(
  const int nEvents = 1,
  const string &jettrigger = "Jet30", // or "PhotonJet"
  const string &outputFile = "G4Hits_pythia8_PhotonJet-0000008-00000.root",
  const string &embed_input_file = "https://www.phenix.bnl.gov/WWW/publish/phnxbld/sPHENIX/files/sPHENIX_G4Hits_sHijing_9-11fm_00000_00010.root",
  const int skip = 0,
  const string &outdir = ".")
{
  Fun4AllServer *se = Fun4AllServer::instance();
  se->Verbosity(1);

  //Opt to print all random seed used for debugging reproducibility. Comment out to reduce stdout prints.
  PHRandomSeed::Verbosity(1);

  // just if we set some flags somewhere in this macro
  recoConsts *rc = recoConsts::instance();
  // By default every random number generator uses
  // PHRandomSeed() which reads /dev/urandom to get its seed
  // if the RANDOMSEED flag is set its value is taken as seed
  // You can either set this to a random value using PHRandomSeed()
  // which will make all seeds identical (not sure what the point of
  // this would be:
  //  rc->set_IntFlag("RANDOMSEED",PHRandomSeed());
  // or set it to a fixed value so you can debug your code
  //  rc->set_IntFlag("RANDOMSEED", 12345);
  //int seedValue = 491258969;
  //rc->set_IntFlag("RANDOMSEED", seedValue);

  //===============
  // conditions DB flags
  //===============
  Enable::CDB = true;
  // global tag
  rc->set_StringFlag("CDB_GLOBALTAG",CDB::global_tag);
  // 64 bit timestamp
  rc->set_uint64Flag("TIMESTAMP",CDB::timestamp);

  pair<int, int> runseg = Fun4AllUtils::GetRunSegment(outputFile);
  int runnumber=runseg.first;
  int segment=runseg.second;
  if (runnumber != 0)
  {
    rc->set_IntFlag("RUNNUMBER",runnumber);
    Fun4AllSyncManager *syncman = se->getSyncManager();
    syncman->SegmentNumber(segment);
  }

  //===============
  // Input options
  //===============
  // verbosity setting (applies to all input managers)
  Input::VERBOSITY = 0;

  // Enable this is emulating the nominal pp/pA/AA collision vertex distribution
//  Input::BEAM_CONFIGURATION = Input::AA_COLLISION; // for 2023 sims we want the AA geometry for no pileup sims
  switch(runnumber)
  {
  case 7:
  Input::BEAM_CONFIGURATION = Input::AA_COLLISION; // for 2023 sims we want the AA geometry for no pileup sims
  break;
  case 8:
  Input::BEAM_CONFIGURATION = Input::pp_COLLISION; // for 2023 sims we want the AA geometry for no pileup sims
  break;
  case 9:
  Input::BEAM_CONFIGURATION = Input::pA_COLLISION; // for 2023 sims we want the AA geometry for no pileup sims
  break;
  default:
    cout << "runnnumber " << runnumber << " not implemented" << endl;
    gSystem->Exit(1);
    break;
  }
  Input::PYTHIA8 = true;


  //-----------------
  // Initialize the selected Input/Event generation
  //-----------------
  // This creates the input generator(s)
  string pythia8_config_file = string(getenv("CALIBRATIONROOT")) + "/Generators/JetStructure_TG/";
  if (jettrigger == "PhotonJet")
  {
    pythia8_config_file += "phpythia8_JS_GJ_MDC2.cfg";
  }
  else if (jettrigger == "Jet10")
  {
    pythia8_config_file += "phpythia8_15GeV_JS_MDC2.cfg";
  }
  else if (jettrigger == "Jet20")
  {
    pythia8_config_file += "phpythia8_20GeV_JS_MDC2.cfg";
  }
  else if (jettrigger == "Jet30")
  {
    pythia8_config_file += "phpythia8_30GeV_JS_MDC2.cfg";
  }
  else
  {
    std::cout << "Invalid jet trigger " << jettrigger << std::endl;
    gSystem->Exit(1);
  }
  PYTHIA8::config_file = pythia8_config_file;

  InputInit();

  //--------------
  // Set generator specific options
  //--------------
  // can only be set after InputInit() is called

  if (Input::PYTHIA8)
  {
    PHPy8JetTrigger *p8_js_signal_trigger = new PHPy8JetTrigger();
    p8_js_signal_trigger->SetEtaHighLow(1.5,-1.5); // Set eta acceptance for particles into the jet between +/- 1.5
    p8_js_signal_trigger->SetJetR(0.4);      //Set the radius for the trigger jet
    if (jettrigger == "Jet10")
    {
      p8_js_signal_trigger->SetMinJetPt(10); // require a 10 GeV minimum pT jet in the event
    }
    else if (jettrigger == "Jet20")
    {
      p8_js_signal_trigger->SetMinJetPt(20); // require a 20 GeV minimum pT jet in the event
    }
    else if (jettrigger == "Jet30")
    {
      p8_js_signal_trigger->SetMinJetPt(30); // require a 30 GeV minimum pT jet in the event
    }
    else if (jettrigger == "PhotonJet")
    {
      delete p8_js_signal_trigger;
      p8_js_signal_trigger = nullptr;
      cout << "no cut for PhotonJet" << endl;
    }
    else
    {
      cout << "invalid jettrigger: " << jettrigger << endl;
      gSystem->Exit(1);
    }
    if (p8_js_signal_trigger)
    {
      INPUTGENERATOR::Pythia8->register_trigger(p8_js_signal_trigger);
      INPUTGENERATOR::Pythia8->set_trigger_AND();
    }
    Input::ApplysPHENIXBeamParameter(INPUTGENERATOR::Pythia8);
  }

  // register all input generators with Fun4All
  InputRegister();

  SyncReco *sync = new SyncReco();
  se->registerSubsystem(sync);

  HeadReco *head = new HeadReco();
  se->registerSubsystem(head);

  FlagHandler *flag = new FlagHandler();
  se->registerSubsystem(flag);

  // set up production relatedstuff
  Enable::PRODUCTION = true;

  //======================
  // Write the DST
  //======================

  Enable::DSTOUT = true;
  Enable::DSTOUT_COMPRESS = false;
  DstOut::OutputDir = outdir;
  DstOut::OutputFile = outputFile;

  //Option to convert DST to human command readable TTree for quick poke around the outputs
  //  Enable::DSTREADER = true;

  //======================
  // What to run
  //======================

  // Global options (enabled for all enables subsystems - if implemented)
  //  Enable::ABSORBER = true;
  //  Enable::OVERLAPCHECK = true;
  //  Enable::VERBOSITY = 1;

  Enable::BBC = true;
//  Enable::BBCFAKE = true;  // Smeared vtx and t0, use if you don't want real BBC in simulation

  Enable::PIPE = true;
//  Enable::PIPE_ABSORBER = true;

  // central tracking
  Enable::MVTX = true;

  Enable::INTT = true;

  Enable::TPC = true;

  Enable::MICROMEGAS = true;

  //  cemc electronics + thin layer of W-epoxy to get albedo from cemc
  //  into the tracking, cannot run together with CEMC
  //  Enable::CEMCALBEDO = true;

  Enable::CEMC = true;

  Enable::HCALIN = true;
  Enable::HCALIN_OLD = true;

  Enable::MAGNET = true;
//  Enable::MAGNET_ABSORBER = false;

  Enable::HCALOUT = true;
  Enable::HCALOUT_OLD = true;

  Enable::EPD = true;

  //! forward flux return plug door. Out of acceptance and off by default.
//  Enable::PLUGDOOR = true;
  Enable::PLUGDOOR_BLACKHOLE = true;
//  Enable::PLUGDOOR_ABSORBER = true;

//  Enable::BEAMLINE = true;
  G4BEAMLINE::skin_thickness = 0.5;
//  Enable::BEAMLINE_ABSORBER = true;  // makes the beam line magnets sensitive volumes
//  Enable::BEAMLINE_BLACKHOLE = true; // turns the beamline magnets into black holes
//  Enable::ZDC = true;
//  Enable::ZDC_ABSORBER = true;
//  Enable::ZDC_SUPPORT = true;
//  Enable::ZDC_TOWER = Enable::ZDC && true;
  Enable::ZDC_EVAL = Enable::ZDC_TOWER && true;
//  Enable::GLOBAL_RECO = true;
  //Enable::GLOBAL_FASTSIM = true;
  
  // new settings using Enable namespace in GlobalVariables.C
  Enable::BLACKHOLE = true;
  Enable::BLACKHOLE_FORWARD_SAVEHITS = false; // disable forward/backward hits
  //Enable::BLACKHOLE_SAVEHITS = false; // turn off saving of bh hits
  //BlackHoleGeometry::visible = true;

  // run user provided code (from local G4_User.C)
  //Enable::USER = true;

  //---------------
  // World Settings
  //---------------
  //  G4WORLD::PhysicsList = "QGSP_BERT"; //FTFP_BERT_HP best for calo
  //  G4WORLD::WorldMaterial = "G4_AIR"; // set to G4_GALACTIC for material scans

  //---------------
  // Magnet Settings
  //---------------

  //  const string magfield = "1.5"; // alternatively to specify a constant magnetic field, give a float number, which will be translated to solenoidal field in T, if string use as fieldmap name (including path)
  //  G4MAGNET::magfield = string(getenv("CALIBRATIONROOT")) + string("/Field/Map/sPHENIX.2d.root");  // default map from the calibration database
//  G4MAGNET::magfield_rescale = -1.4 / 1.5;  // make consistent with expected Babar field strength of 1.4T

  //---------------
  // Pythia Decayer
  //---------------
  // list of decay types in
  // $OFFLINE_MAIN/include/g4decayer/EDecayType.hh
  // default is All:
  // G4P6DECAYER::decayType = EDecayType::kAll;

  // Initialize the selected subsystems
  G4Init();

  //---------------------
  // GEANT4 Detector description
  //---------------------
  if (!Input::READHITS)
  {
    G4Setup();
  }

  //--------------
  // Set up Input Managers
  //--------------

  InputManagers();

  if (Enable::PRODUCTION)
  {
    Production_CreateOutputDir();
  }
  if (Enable::DSTOUT)
  {
    string FullOutFile = DstOut::OutputFile;
    Fun4AllDstOutputManager *out = new Fun4AllDstOutputManager("DSTOUT", FullOutFile);
    se->registerOutputManager(out);
  }
  //-----------------
  // Event processing
  //-----------------
  // if we use a negative number of events we go back to the command line here
  if (nEvents < 0)
  {
    return 0;
  }
  // if we run the particle generator and use 0 it'll run forever
  if (nEvents == 0 && !Input::HEPMC && !Input::READHITS)
  {
    cout << "using 0 for number of events is a bad idea when using particle generators" << endl;
    cout << "it will run forever, so I just return without running anything" << endl;
    return 0;
  }

  se->skip(skip);
  se->run(nEvents);

  //-----
  // Exit
  //-----

  CDBInterface::instance()->Print(); // print used DB files
  se->End();
  std::cout << "All done" << std::endl;
  delete se;
  if (Enable::PRODUCTION)
  {
    Production_MoveOutput();
  }

  gSystem->Exit(0);
  return 0;
}
#endif
