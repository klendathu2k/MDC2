#ifndef FUN4ALL_YEAR1_C
#define FUN4ALL_YEAR1_C

#include <G4_Production.C>

#include <caloreco/CaloTowerBuilder.h>
#include <caloreco/CaloTowerCalib.h>
#include <caloreco/CaloTowerStatus.h>
#include <caloreco/CaloWaveformProcessing.h>
#include <caloreco/DeadHotMapLoader.h>
#include <caloreco/RawClusterBuilderTemplate.h>
#include <caloreco/RawClusterDeadHotMask.h>
#include <caloreco/RawClusterPositionCorrection.h>
#include <caloreco/TowerInfoDeadHotMask.h>

#include <mbd/MbdReco.h>

#include <globalvertex/GlobalVertexReco.h>

#include <ffamodules/CDBInterface.h>
#include <ffamodules/FlagHandler.h>
#include <ffamodules/HeadReco.h>
#include <ffamodules/SyncReco.h>

#include <fun4allraw/Fun4AllPrdfInputManager.h>

#include <fun4all/Fun4AllDstInputManager.h>
#include <fun4all/Fun4AllDstOutputManager.h>
#include <fun4all/Fun4AllInputManager.h>
#include <fun4all/Fun4AllRunNodeInputManager.h>
#include <fun4all/Fun4AllServer.h>
#include <fun4all/Fun4AllUtils.h>
#include <fun4all/SubsysReco.h>

#include <phool/recoConsts.h>

R__LOAD_LIBRARY(libfun4all.so)
R__LOAD_LIBRARY(libfun4allraw.so)
R__LOAD_LIBRARY(libcalo_reco.so)
R__LOAD_LIBRARY(libffamodules.so)
R__LOAD_LIBRARY(libmbd.so)
R__LOAD_LIBRARY(libglobalvertex.so)

void Fun4All_Year1(int nEvents = 5,
                   const std::string &lfn = "beam-00023053-0201.prdf",
                   const std::string &outputFile = "DST_CALO-00023053-0201.root",
                   const std::string &outdir = ".",
                   const std::string &cdbtag = "2023p004")
{
  bool enableMasking = 0;
  bool addZeroSupCaloNodes = 1;
  // v1 uncomment:
  // CaloTowerDefs::BuilderType buildertype = CaloTowerDefs:::kPRDFTowerv1;
  // v2 uncomment:
  CaloTowerDefs::BuilderType buildertype = CaloTowerDefs::kWaveformTowerv2;
  // v3 uncomment:
  // CaloTowerDefs::BuilderType buildertype = CaloTowerDefs::kPRDFWaveform;

  Fun4AllServer *se = Fun4AllServer::instance();
  se->Verbosity(1);

  recoConsts *rc = recoConsts::instance();

  pair<int, int> runseg = Fun4AllUtils::GetRunSegment(lfn);
  int runnumber = runseg.first;
  int segment = runseg.second;

  //===============
  // conditions DB flags
  //===============
  // ENABLE::CDB = true;
  // global tag
  rc->set_StringFlag("CDB_GLOBALTAG", cdbtag);
  // // 64 bit timestamp
  rc->set_uint64Flag("TIMESTAMP", runnumber);
  CDBInterface::instance()->Verbosity(1);

  // set up production relatedstuff
  Enable::PRODUCTION = true;
  //======================
  // Write the DST
  //======================

  Enable::DSTOUT = true;
  Enable::DSTOUT_COMPRESS = false;
  DstOut::OutputDir = outdir;
  DstOut::OutputFile = outputFile;

  // Sync Headers and Flags
  SyncReco *sync = new SyncReco();
  se->registerSubsystem(sync);

  HeadReco *head = new HeadReco();
  se->registerSubsystem(head);

  FlagHandler *flag = new FlagHandler();
  se->registerSubsystem(flag);

  // MBD/BBC Reconstruction
  MbdReco *mbdreco = new MbdReco();
  se->registerSubsystem(mbdreco);

  // Official vertex storage
  GlobalVertexReco *gvertex = new GlobalVertexReco();
  se->registerSubsystem(gvertex);

  /////////////////
  // build towers
  CaloTowerBuilder *ctbEMCal = new CaloTowerBuilder("EMCalBUILDER");
  ctbEMCal->set_detector_type(CaloTowerDefs::CEMC);
  ctbEMCal->set_processing_type(CaloWaveformProcessing::TEMPLATE);
  ctbEMCal->set_builder_type(buildertype);
  ctbEMCal->set_nsamples(16);
  se->registerSubsystem(ctbEMCal);

  CaloTowerBuilder *ctbIHCal = new CaloTowerBuilder("HCALINBUILDER");
  ctbIHCal->set_detector_type(CaloTowerDefs::HCALIN);
  ctbIHCal->set_processing_type(CaloWaveformProcessing::TEMPLATE);
  ctbIHCal->set_builder_type(buildertype);
  ctbIHCal->set_nsamples(31);
  se->registerSubsystem(ctbIHCal);

  CaloTowerBuilder *ctbOHCal = new CaloTowerBuilder("HCALOUTBUILDER");
  ctbOHCal->set_detector_type(CaloTowerDefs::HCALOUT);
  ctbOHCal->set_processing_type(CaloWaveformProcessing::TEMPLATE);
  ctbOHCal->set_builder_type(buildertype);
  ctbOHCal->set_nsamples(31);
  se->registerSubsystem(ctbOHCal);

  CaloTowerBuilder *ca4 = new CaloTowerBuilder("zdc");
  ca4->set_detector_type(CaloTowerDefs::ZDC);
  ca4->set_nsamples(31);
  ca4->set_builder_type(CaloTowerDefs::kPRDFWaveform);
  ca4->set_processing_type(CaloWaveformProcessing::FAST);
  se->registerSubsystem(ca4);

  //////////////////////////////
  // set statuses on raw towers
  std::cout << "status setters" << std::endl;
  CaloTowerStatus *statusEMC = new CaloTowerStatus("CEMCSTATUS");
  statusEMC->set_detector_type(CaloTowerDefs::CEMC);
  se->registerSubsystem(statusEMC);

  CaloTowerStatus *statusHCalIn = new CaloTowerStatus("HCALINSTATUS");
  statusHCalIn->set_detector_type(CaloTowerDefs::HCALIN);
  se->registerSubsystem(statusHCalIn);

  CaloTowerStatus *statusHCALOUT = new CaloTowerStatus("HCALOUTSTATUS");
  statusHCALOUT->set_detector_type(CaloTowerDefs::HCALOUT);
  se->registerSubsystem(statusHCALOUT);

  ////////////////////
  // Calibrate towers
  std::cout << "Calibrating EMCal" << std::endl;
  CaloTowerCalib *calibEMC = new CaloTowerCalib("CEMCCALIB");
  calibEMC->set_detector_type(CaloTowerDefs::CEMC);
  se->registerSubsystem(calibEMC);

  std::cout << "Calibrating OHcal" << std::endl;
  CaloTowerCalib *calibOHCal = new CaloTowerCalib("HCALOUT");
  calibOHCal->set_detector_type(CaloTowerDefs::HCALOUT);
  se->registerSubsystem(calibOHCal);

  std::cout << "Calibrating IHcal" << std::endl;
  CaloTowerCalib *calibIHCal = new CaloTowerCalib("HCALIN");
  calibIHCal->set_detector_type(CaloTowerDefs::HCALIN);
  se->registerSubsystem(calibIHCal);

  std::cout << "Calibrating ZDC" << std::endl;
  CaloTowerCalib *calibZDC = new CaloTowerCalib("ZDC");
  calibZDC->set_detector_type(CaloTowerDefs::ZDC);
  se->registerSubsystem(calibZDC);

  /////////////
  // masking
  if (enableMasking)
  {
    std::cout << "Loading EMCal deadmap" << std::endl;
    DeadHotMapLoader *towerMapCemc = new DeadHotMapLoader("CEMC");
    towerMapCemc->detector("CEMC");
    se->registerSubsystem(towerMapCemc);

    std::cout << "Loading ihcal deadmap" << std::endl;
    DeadHotMapLoader *towerMapHCalin = new DeadHotMapLoader("HCALIN");
    towerMapHCalin->detector("HCALIN");
    se->registerSubsystem(towerMapHCalin);

    std::cout << "Loading ohcal deadmap" << std::endl;
    DeadHotMapLoader *towerMapHCalout = new DeadHotMapLoader("HCALOUT");
    towerMapHCalout->detector("HCALOUT");
    se->registerSubsystem(towerMapHCalout);

    std::cout << "Loading cemc masker" << std::endl;
    TowerInfoDeadHotMask *towerMaskCemc = new TowerInfoDeadHotMask("CEMC");
    towerMaskCemc->detector("CEMC");
    se->registerSubsystem(towerMaskCemc);

    std::cout << "Loading hcal maskers" << std::endl;
    TowerInfoDeadHotMask *towerMaskHCalin = new TowerInfoDeadHotMask("HCALIN");
    towerMaskHCalin->detector("HCALIN");
    se->registerSubsystem(towerMaskHCalin);

    TowerInfoDeadHotMask *towerMaskHCalout = new TowerInfoDeadHotMask("HCALOUT");
    towerMaskHCalout->detector("HCALOUT");
    se->registerSubsystem(towerMaskHCalout);
  }

  std::cout << "Adding Geometry file" << std::endl;
  Fun4AllInputManager *intrue2 = new Fun4AllRunNodeInputManager("DST_GEO");
  std::string geoLocation = CDBInterface::instance()->getUrl("calo_geo");
  intrue2->AddFile(geoLocation);
  se->registerInputManager(intrue2);

  //////////////////
  // Clusters
  std::cout << "Building clusters" << std::endl;
  RawClusterBuilderTemplate *ClusterBuilder = new RawClusterBuilderTemplate("EmcRawClusterBuilderTemplate");
  ClusterBuilder->Detector("CEMC");
  ClusterBuilder->set_threshold_energy(0.030);  // for when using basic calibration
  std::string emc_prof = getenv("CALIBRATIONROOT");
  emc_prof += "/EmcProfile/CEMCprof_Thresh30MeV.root";
  ClusterBuilder->LoadProfile(emc_prof);
  ClusterBuilder->set_UseTowerInfo(1);  // to use towerinfo objects rather than old RawTower
  se->registerSubsystem(ClusterBuilder);

  if (enableMasking)
  {
    std::cout << "Masking clusters" << std::endl;
    RawClusterDeadHotMask *clusterMask = new RawClusterDeadHotMask("clusterMask");
    clusterMask->detector("CEMC");
    se->registerSubsystem(clusterMask);
  }

  std::cout << "Applying Position Dependent Correction" << std::endl;
  RawClusterPositionCorrection *clusterCorrection = new RawClusterPositionCorrection("CEMC");
  clusterCorrection->set_UseTowerInfo(1);  // to use towerinfo objects rather than old RawTower
  se->registerSubsystem(clusterCorrection);

  ///////////////////////////////////////////
  // Calo node with software zero supression
  if (addZeroSupCaloNodes)
  {
    CaloTowerBuilder *ctbEMCal_SZ = new CaloTowerBuilder("EMCalBUILDER_ZS");
    ctbEMCal_SZ->set_detector_type(CaloTowerDefs::CEMC);
    ctbEMCal_SZ->set_processing_type(CaloWaveformProcessing::TEMPLATE);
    ctbEMCal_SZ->set_nsamples(8);
    ctbEMCal_SZ->set_outputNodePrefix("TOWERS_SZ_");
    ctbEMCal_SZ->set_softwarezerosuppression(true, 100000000);
    se->registerSubsystem(ctbEMCal_SZ);

    CaloTowerBuilder *ctbIHCal_SZ = new CaloTowerBuilder("HCALINBUILDER_ZS");
    ctbIHCal_SZ->set_detector_type(CaloTowerDefs::HCALIN);
    ctbIHCal_SZ->set_processing_type(CaloWaveformProcessing::TEMPLATE);
    ctbIHCal_SZ->set_nsamples(8);
    ctbIHCal_SZ->set_outputNodePrefix("TOWERS_SZ_");
    ctbIHCal_SZ->set_softwarezerosuppression(true, 100000000);
    se->registerSubsystem(ctbIHCal_SZ);

    CaloTowerBuilder *ctbOHCal_SZ = new CaloTowerBuilder("HCALOUTBUILDER_SZ");
    ctbOHCal_SZ->set_detector_type(CaloTowerDefs::HCALOUT);
    ctbOHCal_SZ->set_processing_type(CaloWaveformProcessing::TEMPLATE);
    ctbOHCal_SZ->set_nsamples(8);
    ctbOHCal_SZ->set_outputNodePrefix("TOWERS_SZ_");
    ctbOHCal_SZ->set_softwarezerosuppression(true, 100000000);
    se->registerSubsystem(ctbOHCal_SZ);

    CaloTowerCalib *calibEMC_SZ = new CaloTowerCalib("CEMCCALIB_SZ");
    calibEMC_SZ->set_detector_type(CaloTowerDefs::CEMC);
    calibEMC_SZ->set_inputNodePrefix("TOWERS_SZ_");
    calibEMC_SZ->set_outputNodePrefix("TOWERINFO_SZ_CALIB_");
    se->registerSubsystem(calibEMC_SZ);

    CaloTowerCalib *calibIHCal_SZ = new CaloTowerCalib("IHCALCALIB_SZ");
    calibIHCal_SZ->set_detector_type(CaloTowerDefs::HCALIN);
    calibIHCal_SZ->set_inputNodePrefix("TOWERS_SZ_");
    calibIHCal_SZ->set_outputNodePrefix("TOWERINFO_SZ_CALIB_");
    se->registerSubsystem(calibIHCal_SZ);

    CaloTowerCalib *calibOHCal_SZ = new CaloTowerCalib("OHCALCALIB_SZ");
    calibOHCal_SZ->set_detector_type(CaloTowerDefs::HCALOUT);
    calibOHCal_SZ->set_inputNodePrefix("TOWERS_SZ_");
    calibOHCal_SZ->set_outputNodePrefix("TOWERINFO_SZ_CALIB_");
    se->registerSubsystem(calibOHCal_SZ);
  }

  Fun4AllInputManager *In = new Fun4AllPrdfInputManager("in");
  In->AddFile(lfn);
  se->registerInputManager(In);

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

  se->run(nEvents);
  se->End();
  CDBInterface::instance()->Print();  // print used DB files
  se->PrintTimer();
  delete se;
  if (Enable::PRODUCTION)
  {
    Production_MoveOutput();
  }
  std::cout << "All done!" << std::endl;
  gSystem->Exit(0);
}

#endif
