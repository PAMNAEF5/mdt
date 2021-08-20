USE `es_extended`;

CREATE TABLE `mdw_reports` (
  `id` varchar(100) NOT NULL,
  `incident` int(11) NOT NULL,
  `title` varchar(100) NOT NULL,
  `description` longtext NOT NULL,
  `ongoing` tinyint(1) NOT NULL,
  `expire` varchar(100) NOT NULL,
  `created` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `mdw_incidents` (
  `id` varchar(100) NOT NULL,
  `title` varchar(100) NOT NULL,
  `location` varchar(100) NOT NULL,
  `time` varchar(100) NOT NULL,
  `description` longtext NOT NULL,
  `data` longtext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `mdw_evidence` (
  `id` varchar(100) NOT NULL,
  `image` varchar(100) NOT NULL,
  `description` longtext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `mdw_announcements` (
  `id` int(11) NOT NULL,
  `announcement` longtext NOT NULL,
  `date` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE `mdw_announcements`
  ADD PRIMARY KEY (`id`);

ALTER TABLE `mdw_announcements`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

ALTER TABLE `users`
ADD (`mdw_image` varchar(1000) COLLATE utf8mb4_bin NOT NULL,
  `mdw_description` longtext COLLATE utf8mb4_bin NOT NULL,
  `mdw_alias` varchar(100) COLLATE utf8mb4_bin NOT NULL,
  `mdw_staffdata` longtext COLLATE utf8mb4_bin NOT NULL);

