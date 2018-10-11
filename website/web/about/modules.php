<?php
session_start();
require '../vendor/autoload.php';
$mongo = new MongoDB\Client('mongodb://localhost:27017'); //Acces au SGBD
?>
<!DOCTYPE html>
<html lang="en">
       <head>
       <title>Logipedia</title>
       <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.1.0/css/bootstrap.min.css" integrity="sha384-9gVQ4dYFwwWSjIDZnLEWnxCjeSWFphJiwGPXr1jddIhOegiu1FwO5qRGvFXOdJZ4" crossorigin="anonymous">
       <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.1.0/css/all.css" integrity="sha384-lKuwvrZot6UHsBSfcMvOkWwlCMgc0TaWr+30HWe3a4ltaBwTZhyTEggF5tJv8tbt" crossorigin="anonymous">
       <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js"></script>
       <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.1.0/js/bootstrap.min.js" integrity="sha384-uefMccjFJAIv6A+rW+L4AHf99KvxDjWSu1z9VI8SKNVmz4sk7buKt/6v9KI65qnm" crossorigin="anonymous"></script>
       <link rel="stylesheet" type="text/css" href="about.css">
       </head>
       <body>
       <nav class="navbar navbar-expand-md bg-dark navbar-dark fixed-top">
       <div class="container">
       <a class="navbar-brand" href="../index.php"><i class="fas fa-award"></i> Logipedia</a>
       <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#collapsibleNavbar">
       <span class="navbar-toggler-icon"></span>
       </button>
       <div class="collapse navbar-collapse" id="collapsibleNavbar">
       <ul class="navbar-nav">
       <li class="nav-item">
       <a class="nav-link" href="about.php">About</a>
       </li>
       <li class="nav-item">
       <a class="nav-link" href="#">Modules</a>
       </li>
       </ul>
       </div>
       </div>
       </nav>
       <!--
       <hr class="my-4">
       <div class="row">
       <div class="col-md-3 col-sm-3 col-3"> </div>
       <h4 class="h4-color"> This page lists all the modules available in Logipedia</h4>
       </div>
       -->
       <hr class="my-4">

       <div class="container">
       <div class="list-group">
       <?php
       $collection  = $mongo->logipedia->mdDep;
       $query       = $collection->find([], ['projection' => ['_id' => false]]);
       $all_modules = [];
       foreach($query as $dep_md) {
           if(!(in_array($dep_md['mdDep'], $all_modules))) {
               array_push($all_modules, $dep_md['mdDep']);
           }
           if(!(in_array($dep_md['md'], $all_modules))) {
               array_push($all_modules, $dep_md['md']);
           }
       }
       foreach($all_modules as $md) {
           echo '<a href="../index.php?search='.$md.'" class="list-group-item list-group-item-action text-center list-group-bg-mar">';
           echo '<h4 class="h4-color"><b>'.$md.'</b></h4>';
           echo '</a>';
       }
       ?>
       </div>
       </div>
       </br>
       <script src="about.js"></script>
       </body>
       </html>